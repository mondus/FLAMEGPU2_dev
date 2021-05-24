#ifndef INCLUDE_FLAMEGPU_IO_XMLLOGGER_H_
#define INCLUDE_FLAMEGPU_IO_XMLLOGGER_H_

#include <string>
#include <typeindex>

#include "flamegpu/io/Logger.h"
#include "flamegpu/util/Any.h"

struct Any;
struct RunLog;
struct LogFrame;
class RunPlan;
namespace tinyxml2 {
class XMLNode;
class XMLDocument;
class XMLElement;
}  // namespace tinyxml2

/**
 * XML format Logger
 */
class xmlLogger : public Logger{
 public:
    xmlLogger(const std::string &outPath, bool prettyPrint, bool truncateFile);
    /**
     * Log a runlog to file, using a RunPlan in place of config
     * @throws May throw exceptions if logging to file failed for any reason
     */
    void log(const RunLog &log, const RunPlan &plan, bool logSteps = true, bool logExit = true) const override;
    /**
     * Log a runlog to file, uses config data (random seed) from the RunLog
     * @throws May throw exceptions if logging to file failed for any reason
     */
    void log(const RunLog &log, bool logConfig = true, bool logSteps = true, bool logExit = true) const override;

 private:
    /**
     * Internal logging method, allows Plan to be passed as null
     */
    void logCommon(const RunLog &log, const RunPlan *plan, bool logConfig, bool logSteps, bool logExit) const;
    /**
     * Writes out the run config via a JSON object to the provided node
     * @param doc tinyxml2 document used for allocating the new element
     * @param log RunLog containing the config items to be written
     * @return The created XMLNode, the calling method will then add it to the main XML hierarchy
     */
    tinyxml2::XMLNode *logConfig(tinyxml2::XMLDocument &doc, const RunLog &log) const;
    /**
     * Writes out step logs as a JSON array to the provided node
     * @param doc tinyxml2 document used for allocating the new element
     * @param plan RunPlan containing the config items to be written
     * @return The created XMLNode, the calling method will then add it to the main XML hierarchy
     */
    tinyxml2::XMLNode *logConfig(tinyxml2::XMLDocument &doc, const RunPlan &plan) const;
    /**
     * Writes out step logs as a JSON array to the provided node
     * @param doc tinyxml2 document used for allocating the new element
     * @param log RunLog containing the step logs to be written
     * @return The created XMLNode, the calling method will then add it to the main XML hierarchy
     */
    tinyxml2::XMLNode *logSteps(tinyxml2::XMLDocument &doc, const RunLog &log) const;
    /**
     * Writes out an exit log as a JSON object to the provided node
     * @param doc tinyxml2 document used for allocating the new element
     * @param log RunLog containing the exit log to be written
     * @return The created XMLNode, the calling method will then add it to the main XML hierarchy
     */
    tinyxml2::XMLNode *logExit(tinyxml2::XMLDocument &doc, const RunLog &log) const;
    /**
     * Writes out a LogFrame instance as a JSON object to the provided node
     * @param doc tinyxml document to append the log frame to
     * @param log LogFrame to be written
     * @return The created XMLNode, the calling method will then add it to the main XML hierarchy
     */
    tinyxml2::XMLNode *writeLogFrame(tinyxml2::XMLDocument &doc, const LogFrame &log) const;
    /**
     * Writes out the value of an Any to the provided node
     * @param element The element to set the value of
     * @param value The Any to be written
     * @param elements The number of individual elements stored in the Any (1 if not an array)
     * @tparam T Instance of rapidjson::Writer or subclass (e.g. rapidjson::PrettyWriter)
     * @note Templated as can't forward declare rapidjson::Writer<rapidjson::StringBuffer>
     */
    void writeAny(tinyxml2::XMLElement *element, const Any &value, const unsigned int &elements = 1) const;

    std::string out_path;
    bool prettyPrint;
    bool truncateFile;
};

#endif  // INCLUDE_FLAMEGPU_IO_XMLLOGGER_H_
