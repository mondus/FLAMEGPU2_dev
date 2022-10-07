#ifndef INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGESPATIAL3D_MESSAGESPATIAL3DHOST_H_
#define INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGESPATIAL3D_MESSAGESPATIAL3DHOST_H_

#include <memory>
#include <string>

#include "flamegpu/util/nvtx.h"
#include "flamegpu/runtime/messaging/MessageSpatial3D.h"
#include "flamegpu/runtime/messaging/MessageSpatial2D/MessageSpatial2DHost.h"
#include "flamegpu/runtime/messaging/MessageBruteForce/MessageBruteForceHost.h"

class CUDAMessage;

namespace flamegpu {

/**
 * CUDA host side handler of spatial messages
 * Allocates memory for and constructs PBM
 */
class MessageSpatial3D::CUDAModelHandler : public MessageSpecialisationHandler {
    friend class MessageSpatial3D::HostAPI;

 public:
    /**
     * Constructor
     * 
     * Initialises metadata, decides PBM size etc
     * 
     * @param a Parent CUDAMessage, used to access message settings, data ptrs etc
     */
     explicit CUDAModelHandler(CUDAMessage& a);
    /**
     * Destructor
     * Frees all alocated memory
     */
    ~CUDAModelHandler() override { }
    /**
     * Allocates memory for the constructed index.
     * Sets data asthough message list is empty
     * @param scatter Scatter instance and scan arrays to be used (CUDASimulation::singletons->scatter)
     * @param streamId Index of stream specific structures used
     * @param stream The CUDAStream to use for CUDA operations
     */
    void init(CUDAScatter &scatter, unsigned int streamId, cudaStream_t stream) override;
    /**
     * Reconstructs the partition boundary matrix
     * This should be called before reading newly output messages
     * @param scatter Scatter instance and scan arrays to be used (CUDASimulation::singletons->scatter)
     * @param streamId The stream index to use for accessing stream specific resources such as scan compaction arrays and buffers
     * @param stream The CUDAStream to use for CUDA operations
     */
    void buildIndex(CUDAScatter &scatter, unsigned int streamId, cudaStream_t stream) override;
    /**
     * Allocates memory for the constructed index.
     * The memory allocation is checked by build index.
     */
    void allocateMetaDataDevicePtr(cudaStream_t stream) override;
    /**
     * Releases memory for the constructed index.
     */
    void freeMetaDataDevicePtr() override;
    /**
     * Returns a pointer to the metadata struct, this is required for reading the message data
     */
    const void *getMetaDataDevicePtr() const override { return d_data; }
    /**
     * On next PBM rebuild the pbm may be reallocated and metadata updated on device
     */
    void setMetadataChangedFlag() { metadata_changed_flag = true; }

 private:
    /**
     * Resizes the cub temp memory
     * Currently assumed that bounds of environment/rad never change
     * So this is only called from the constructor.
     * If it were called elsewhere, it would need to be changed to resize d_histogram too
     */
    void resizeCubTemp(cudaStream_t stream);
    /**
     * Resizes the key value store, this scales with agent count
     * @param newSize The new number of agents to represent
     * @note This only scales upwards, it will never reduce the size
     */
    void resizeKeysVals(const unsigned int &newSize);
    /**
     * Number of bins, arrays are +1 this length
     */
    unsigned int binCount = 0;
    /**
     * Number of bins in hd_data.PBM
     */
    unsigned int allocated_binCount = 0;
    /**
     * Size of currently allocated temp storage memory for cub
     */
    size_t d_CUB_temp_storage_bytes = 0;
    /**
     * Pointer to currently allocated temp storage memory for cub
     */
    unsigned int *d_CUB_temp_storage = nullptr;
    /**
     * Pointer to array used for histogram
     */
    unsigned int *d_histogram = nullptr;
    /**
     * Arrays used to store indices when sorting messages
     */
    unsigned int *d_keys = nullptr, *d_vals = nullptr;
    /**
     * Size currently allocated to d_keys, d_vals arrays
     */
    size_t d_keys_vals_storage_bytes = 0;
    /**
     * Host copy of metadata struct
     */
    MetaData hd_data;
    /**
     * Pointer to device copy of metadata struct
     */
    MetaData *d_data = nullptr;
    /**
     * Owning CUDAMessage, provides access to message storage etc
     */
    CUDAMessage &sim_message;
    /**
     * If true, PBM rebuild will realloc a different sized PBM first
     */
    bool metadata_changed_flag;
};

/**
 * Internal data representation of Spatial3D messages within model description hierarchy
 * @see Description
 */
struct MessageSpatial3D::Data : public MessageSpatial2D::Data {
    friend class ModelDescription;
    friend struct ModelData;
    float minZ;
    float maxZ;
    virtual ~Data() = default;

    std::unique_ptr<MessageSpecialisationHandler> getSpecialisationHander(CUDAMessage &owner) const override;

    /**
    * Used internally to validate that the corresponding Message type is attached via the agent function shim.
    * @return The std::type_index of the Message type which must be used.
    */
    std::type_index getType() const override;
    /**
     * Return the sorting type for this message type
     */
    flamegpu::MessageSortingType getSortingType() const override;

 protected:
    Data *clone(const std::shared_ptr<const ModelData> &newParent) override;
    /**
    * Copy constructor
    * This is unsafe, should only be used internally, use clone() instead
    */
    Data(const std::shared_ptr<const ModelData> &, const Data &other);
    /**
    * Normal constructor, only to be called by ModelDescription
    */
    Data(const std::shared_ptr<const ModelData> &, const std::string &message_name);
};

/**
 * User accessible interface to Spatial3D messages within mode description hierarchy
 * @see Data
 */
class MessageSpatial3D::Description : public MessageBruteForce::Description {
    /**
    * Data store class for this description, constructs instances of this class
    */
    friend struct Data;

 protected:
    /**
    * Constructors
    */
    Description(const std::shared_ptr<const ModelData> &_model, Data *const data);
    /**
    * Default copy constructor, not implemented
    */
    Description(const Description &other_message) = delete;
    /**
    * Default move constructor, not implemented
    */
    Description(Description &&other_message) noexcept = delete;
    /**
    * Default copy assignment, not implemented
    */
    Description& operator=(const Description &other_message) = delete;
    /**
    * Default move assignment, not implemented
    */
    Description& operator=(Description &&other_message) noexcept = delete;

 public:
    void setRadius(const float &r);
    void setMinX(const float &x);
    void setMinY(const float &y);
    void setMinZ(const float &z);
    void setMin(const float &x, const float &y, const float &z);
    void setMaxX(const float &x);
    void setMaxY(const float &y);
    void setMaxZ(const float &z);
    void setMax(const float &x, const float &y, const float &z);

    float getRadius() const;
    float getMinX() const;
    float getMinY() const;
    float getMinZ() const;
    float getMaxX() const;
    float getMaxY() const;
    float getMaxZ() const;
};

class MessageSpatial3D::HostAPI {
    CUDAMessage &cudaMessage;
    CUDAModelHandler &messageHandler;

 public:
    HostAPI(CUDAMessage &_cudaMessage, CUDAModelHandler &_messageHandler)
        : cudaMessage(_cudaMessage)
        , messageHandler(_messageHandler) { }
    void setRadius(const float& r);
    void setMinX(const float& x);
    void setMinY(const float& y);
    void setMinZ(const float& z);
    void setMin(const float& x, const float& y, const float& z);
    void setMaxX(const float& x);
    void setMaxY(const float& y);
    void setMaxZ(const float& z);
    void setMax(const float& x, const float& y, const float& z);
    void clearMessages();

    float getRadius() const {
        return messageHandler.hd_data.radius;
    }
    float getMinX() const {
        return messageHandler.hd_data.min[0];
    }
    float getMinY() const {
        return messageHandler.hd_data.min[1];
    }
    float getMinZ() const {
        return messageHandler.hd_data.min[2];
    }
    float getMaxX() const {
        return messageHandler.hd_data.max[0];
    }
    float getMaxY() const {
        return messageHandler.hd_data.max[1];
    }
    float getMaxZ() const {
        return messageHandler.hd_data.max[2];
    }
};

}  // namespace flamegpu

#endif  // INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGESPATIAL3D_MESSAGESPATIAL3DHOST_H_
