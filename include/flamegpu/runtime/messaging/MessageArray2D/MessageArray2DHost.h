#ifndef INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGEARRAY2D_MESSAGEARRAY2DHOST_H_
#define INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGEARRAY2D_MESSAGEARRAY2DHOST_H_

#include <string>
#include <memory>
#include <array>

#include "flamegpu/model/Variable.h"
#include "flamegpu/runtime/messaging/MessageArray2D.h"
#include "flamegpu/runtime/messaging/MessageBruteForce/MessageBruteForceHost.h"


namespace flamegpu {

/**
 * Blank handler, brute force requires no index or special allocations
 * Only stores the length on device
 */
class MessageArray2D::CUDAModelHandler : public MessageSpecialisationHandler {
 public:
    /**
     * Constructor
     * Allocates memory on device for message list length
     * @param a Parent CUDAMessage, used to access message settings, data ptrs etc
     */
     explicit CUDAModelHandler(CUDAMessage &a);
    /** 
     * Destructor.
     * Should free any local host memory (device memory cannot be freed in destructors)
     */
    ~CUDAModelHandler() { }
    /**
     * Allocates memory for the constructed index.
     * Allocates message buffers, and memsets data to 0
     * @param scatter Scatter instance and scan arrays to be used (CUDASimulation::singletons->scatter)
     * @param streamId The stream index to use for accessing stream specific resources such as scan compaction arrays and buffers
     * @param stream The CUDAStream to use for CUDA operations
     */
    void init(CUDAScatter &scatter, unsigned int streamId, cudaStream_t stream) override;
    /**
     * Sort messages according to index
     * Detect and report any duplicate indicies/gaps
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
    const void *getMetaDataDevicePtr() const override { return d_metadata; }

 private:
    /**
     * Host copy of metadata struct (message list length)
     */
    MetaData hd_metadata;
    /**
     * Pointer to device copy of metadata struct (message list length)
     */
    MetaData *d_metadata;
    /**
     * Owning CUDAMessage, provides access to message storage etc
     */
    CUDAMessage &sim_message;
    /**
     * Buffer used by buildIndex if array length > agent count
     */
    unsigned int *d_write_flag;
    /**
     * Allocated length of d_write_flag (in number of uint, not bytes)
     */
    size_type d_write_flag_len;
};

/**
 * Internal data representation of Array messages within model description hierarchy
 * @see Description
 */
struct MessageArray2D::Data : public MessageBruteForce::Data {
    friend class ModelDescription;
    friend struct ModelData;
    std::array<size_type, 2> dimensions;
    virtual ~Data() = default;

    std::unique_ptr<MessageSpecialisationHandler> getSpecialisationHander(CUDAMessage &owner) const override;

    /**
     * Used internally to validate that the corresponding Message type is attached via the agent function shim.
     * @return The std::type_index of the Message type which must be used.
     */
    std::type_index getType() const override;

 protected:
    Data *clone(const std::shared_ptr<const ModelData> &newParent) override;
    /**
     * Copy constructor
     * This is unsafe, should only be used internally, use clone() instead
     */
    Data(std::shared_ptr<const ModelData> model, const Data &other);
    /**
     * Normal constructor, only to be called by ModelDescription
     */
    Data(std::shared_ptr<const ModelData> model, const std::string &message_name);
};

class MessageArray2D::CDescription : public MessageBruteForce::CDescription {
    /**
    * Data store class for this description, constructs instances of this class
    */
    friend struct Data;

 public:
    /**
     * Constructor, creates an interface to the MessageData
     * @param data Data store of this message's data
     */
    explicit CDescription(std::shared_ptr<Data> data);
    explicit CDescription(std::shared_ptr<const Data> data);
    /**
     * Copy constructor
     * Creates a new interface to the same MessageData/ModelData
     */
    CDescription(const CDescription& other_agent) = default;
    CDescription(CDescription&& other_agent) = default;
    /**
     * Assignment operator
     * Assigns this interface to the same MessageData/ModelData
     */
    CDescription& operator=(const CDescription& other_agent) = default;
    CDescription& operator=(CDescription&& other_agent) = default;
    /**
     * Equality operator, checks whether message Description hierarchies are functionally the same
     * @param rhs right hand side
     * @returns True when messages are the same
     * @note Instead compare pointers if you wish to check that they are the same instance
     */
    bool operator==(const CDescription& rhs) const;
    /**
     * Equality operator, checks whether message Description hierarchies are functionally different
     * @param rhs right hand side
     * @returns True when messages are not the same
     * @note Instead compare pointers if you wish to check that they are not the same instance
     */
    bool operator!=(const CDescription& rhs) const;

    std::array<size_type, 2> getDimensions() const;
    size_type getDimX() const;
    size_type getDimY() const;
};
/**
 * User accessible interface to Array messages within mode description hierarchy
 * @see Data
 */
class MessageArray2D::Description : public CDescription {
 public:
    /**
     * Constructor, creates an interface to the MessageData
     * @param data Data store of this agent's data
     */
    explicit Description(std::shared_ptr<Data> data);
    /**
     * Copy constructor
     * Creates a new interface to the same MessageData/ModelData
     */
    Description(const Description& other_message) = default;
    Description(Description&& other_message) = default;
    /**
     * Assignment operator
     * Assigns this interface to the same MessageData/ModelData
     */
    Description& operator=(const Description& other_message) = default;
    Description& operator=(Description&& other_message) = default;

    using MessageBruteForce::CDescription::setPersistent;
    using MessageBruteForce::CDescription::newVariable;
#ifdef SWIG
    using MessageBruteForce::CDescription::newVariableArray;
#endif
     void setDimensions(size_type len_x, size_type len_y);
     void setDimensions(const std::array<size_type, 2> &dims);
};

}  // namespace flamegpu

#endif  // INCLUDE_FLAMEGPU_RUNTIME_MESSAGING_MESSAGEARRAY2D_MESSAGEARRAY2DHOST_H_
