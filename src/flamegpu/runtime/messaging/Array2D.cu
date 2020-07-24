#include "flamegpu/runtime/messaging/Array2D.h"
#include "flamegpu/model/AgentDescription.h"  // Used by Move-Assign
#include "flamegpu/gpu/CUDAMessage.h"
#include "flamegpu/gpu/CUDAScatter.h"
#include "flamegpu/exception/FGPUDeviceException_device.h"

/**
* Sets the array index to store the message in
*/
__device__ void MsgArray2D::Out::setIndex(const size_type &x, const size_type &y) const {
    unsigned int index = (blockDim.x * blockIdx.x) + threadIdx.x;
    size_type index_1d =
        y * metadata->dimensions[0] +
        x;
#ifndef NO_SEATBELTS
    if (x >= metadata->dimensions[0] ||
        y >= metadata->dimensions[1]) {
        DTHROW("MsgArray2D index [%u, %u] is out of bounds [%u, %u]\n", x, y, metadata->dimensions[0], metadata->dimensions[1]);
    }
#endif
    // set the variable using curve
    Curve::setVariable<size_type>("___INDEX", combined_hash, index_1d, index);

    // Set scan flag incase the message is optional
    this->scan_flag[index] = 1;
}
__device__ MsgArray2D::In::Filter::Filter(const MetaData *_metadata, const Curve::NamespaceHash &_combined_hash, const size_type &x, const size_type &y, const size_type &_radius)
    : radius(_radius)
    , metadata(_metadata)
    , combined_hash(_combined_hash) {
    loc[0] = x;
    loc[1] = y;
}
__device__ MsgArray2D::In::Filter::Message& MsgArray2D::In::Filter::Message::operator++() {
    if (relative_cell[1] >= static_cast<int>(_parent.radius)) {
        relative_cell[1] = -_parent.radius;
        relative_cell[0]++;
    } else {
        relative_cell[1]++;
    }
    // Skip origin cell
    if (relative_cell[0] == 0 && relative_cell[1] == 0) {
        relative_cell[1]++;
    }
    // Wrap over boundaries
    const unsigned int their_x = (this->_parent.loc[0] + relative_cell[0] + this->_parent.metadata->dimensions[0]) % this->_parent.metadata->dimensions[0];
    const unsigned int their_y = (this->_parent.loc[1] + relative_cell[1] + this->_parent.metadata->dimensions[1]) % this->_parent.metadata->dimensions[1];
    // Solve to 1 dimensional bin index
    index_1d = their_y * this->_parent.metadata->dimensions[0] +
        their_x;
    return *this;
}
/**
 * Constructor
 * Allocates memory on device for message list length
 * @param a Parent CUDAMessage, used to access message settings, data ptrs etc
 */
MsgArray2D::CUDAModelHandler::CUDAModelHandler(CUDAMessage &a)
    : MsgSpecialisationHandler()
    , d_metadata(nullptr)
    , sim_message(a)
    , d_write_flag(nullptr)
    , d_write_flag_len(0) {
    const Data& d = static_cast<const Data &>(a.getMessageDescription());
    memcpy(&hd_metadata.dimensions, d.dimensions.data(), d.dimensions.size() * sizeof(unsigned int));
    hd_metadata.length = d.dimensions[0] * d.dimensions[1];
}

void MsgArray2D::CUDAModelHandler::init(CUDAScatter &scatter, const unsigned int &streamId) {
    allocateMetaDataDevicePtr();
    // Allocate messages
    this->sim_message.resize(hd_metadata.length, scatter, streamId);
    this->sim_message.setMessageCount(hd_metadata.length);
    // Zero the output arrays
    auto &read_list = this->sim_message.getReadList();
    auto &write_list = this->sim_message.getWriteList();
    for (auto &var : this->sim_message.getMessageDescription().variables) {
        // Elements is harmless, futureproof for arrays support
        // hd_metadata.length is used, as message array can be longer than message count
        gpuErrchk(cudaMemset(write_list.at(var.first), 0, var.second.type_size * var.second.elements * hd_metadata.length));
        gpuErrchk(cudaMemset(read_list.at(var.first), 0, var.second.type_size * var.second.elements * hd_metadata.length));
    }
}
void MsgArray2D::CUDAModelHandler::allocateMetaDataDevicePtr() {
    if (d_metadata == nullptr) {
        gpuErrchk(cudaMalloc(&d_metadata, sizeof(MetaData)));
        gpuErrchk(cudaMemcpy(d_metadata, &hd_metadata, sizeof(MetaData), cudaMemcpyHostToDevice));
    }
}

void MsgArray2D::CUDAModelHandler::freeMetaDataDevicePtr() {
    if (d_metadata != nullptr) {
        gpuErrchk(cudaFree(d_metadata));
    }
    d_metadata = nullptr;

    if (d_write_flag) {
        gpuErrchk(cudaFree(d_write_flag));
    }
    d_write_flag = nullptr;
    d_write_flag_len = 0;
}
void MsgArray2D::CUDAModelHandler::buildIndex(CUDAScatter &scatter, const unsigned int &streamId) {
    const unsigned int MESSAGE_COUNT = this->sim_message.getMessageCount();
    // Zero the output arrays
    auto &read_list = this->sim_message.getReadList();
    auto &write_list = this->sim_message.getWriteList();
    for (auto &var : this->sim_message.getMessageDescription().variables) {
        // Elements is harmless, futureproof for arrays support
        // hd_metadata.length is used, as message array can be longer than message count
        gpuErrchk(cudaMemset(write_list.at(var.first), 0, var.second.type_size * var.second.elements * hd_metadata.length));
    }

    // Reorder messages
    unsigned int *t_d_write_flag = nullptr;
    if (MESSAGE_COUNT > hd_metadata.length) {
        // Use internal memory for d_write_flag
        if (d_write_flag_len < MESSAGE_COUNT) {
            // Increase length
            if (d_write_flag) {
                gpuErrchk(cudaFree(d_write_flag));
            }
            d_write_flag_len = static_cast<unsigned int>(MESSAGE_COUNT * 1.1f);
            gpuErrchk(cudaMalloc(&d_write_flag, sizeof(unsigned int) * d_write_flag_len));
        }
        t_d_write_flag = d_write_flag;
    }
    scatter.arrayMessageReorder(streamId, this->sim_message.getMessageDescription().variables, read_list, write_list, MESSAGE_COUNT, hd_metadata.length, t_d_write_flag);
    this->sim_message.swap();
    // Reset message count back to full array length
    // Array message exposes not output messages as 0
    if (MESSAGE_COUNT != hd_metadata.length)
        this->sim_message.setMessageCount(hd_metadata.length);
    // Detect errors
    // TODO
}


MsgArray2D::Data::Data(const std::shared_ptr<const ModelData> &model, const std::string &message_name)
    : MsgBruteForce::Data(model, message_name)
    , dimensions({ 0, 0 }) {
    description = std::unique_ptr<MsgArray2D::Description>(new MsgArray2D::Description(model, this));
    variables.emplace("___INDEX", Variable(1, size_type()));
}
MsgArray2D::Data::Data(const std::shared_ptr<const ModelData> &model, const Data &other)
    : MsgBruteForce::Data(model, other)
    , dimensions(other.dimensions) {
    description = std::unique_ptr<MsgArray2D::Description>(model ? new MsgArray2D::Description(model, this) : nullptr);
    if (dimensions[0] == 0 || dimensions[1] == 0) {
        THROW InvalidMessage("All dimensions must be ABOVE zero in array2D message '%s'\n", other.name.c_str());
    }
}
MsgArray2D::Data *MsgArray2D::Data::clone(const std::shared_ptr<const ModelData> &newParent) {
    return new Data(newParent, *this);
}
std::unique_ptr<MsgSpecialisationHandler> MsgArray2D::Data::getSpecialisationHander(CUDAMessage &owner) const {
    return std::unique_ptr<MsgSpecialisationHandler>(new CUDAModelHandler(owner));
}
std::type_index MsgArray2D::Data::getType() const { return std::type_index(typeid(MsgArray2D)); }


MsgArray2D::Description::Description(const std::shared_ptr<const ModelData> &_model, Data *const data)
    : MsgBruteForce::Description(_model, data) { }

void MsgArray2D::Description::setDimensions(const size_type& len_x, const size_type& len_y) {
    setDimensions({ len_x , len_y });
}
void MsgArray2D::Description::setDimensions(const std::array<size_type, 2> &dims) {
    if (dims[0] == 0 || dims[1] == 0) {
        THROW InvalidArgument("All dimensions must be above zero in array2D message.\n");
    }
    reinterpret_cast<Data *>(message)->dimensions = dims;
}
std::array<MsgArray2D::size_type, 2> MsgArray2D::Description::getDimensions() const {
    return reinterpret_cast<Data *>(message)->dimensions;
}
MsgArray2D::size_type MsgArray2D::Description::getDimX() const {
    return reinterpret_cast<Data *>(message)->dimensions[0];
}
MsgArray2D::size_type MsgArray2D::Description::getDimY() const {
    return reinterpret_cast<Data *>(message)->dimensions[1];
}
