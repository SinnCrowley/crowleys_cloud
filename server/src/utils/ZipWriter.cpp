// ZipWriter implementation for generating PKWARE-compliant ZIP archives.
// Binary Specification: Writes standard Local File Headers (0x04034b50), Central Directory Headers (0x02014b50),
// and End of Central Directory Record (0x06054b50).
// Compression: Uses zlib raw deflate algorithm (-MAX_WBITS) for standard ZIP compatibility and CRC-32 checksum calculation.
// Timestamps: Encodes system time into 16-bit MS-DOS time and date bitfields.

#include "server/utils/ZipWriter.hpp"

#include <algorithm>
#include <chrono>
#include <ctime>
#include <fstream>
#include <zlib.h>

namespace server::utils {

/**
 * Converts current system time into MS-DOS bitfield packed date and time formats.
 * Time format: [bits 0-4: sec/2][bits 5-10: min][bits 11-15: hour]
 * Date format: [bits 0-4: day][bits 5-8: month][bits 9-15: year since 1980]
 */
void ZipWriter::getDosTimeDate(std::uint16_t &dosTime, std::uint16_t &dosDate) {
  auto now = std::chrono::system_clock::to_time_t(std::chrono::system_clock::now());
  std::tm tm{};
#if defined(_WIN32)
  localtime_s(&tm, &now);
#else
  localtime_r(&now, &tm);
#endif

  dosTime = static_cast<std::uint16_t>((tm.tm_sec / 2) | (tm.tm_min << 5) | (tm.tm_hour << 11));
  dosDate = static_cast<std::uint16_t>(tm.tm_mday | ((tm.tm_mon + 1) << 5) | ((std::max(0, tm.tm_year - 80)) << 9));
}

/**
 * Compresses data using raw zlib DEFLATE (-MAX_WBITS) and computes CRC-32 checksum.
 */
bool ZipWriter::compressData(const std::string &raw, std::vector<std::uint8_t> &outCompressed, std::uint32_t &outCrc32) {
  // Step 1: Compute uncompressed payload CRC-32 checksum
  outCrc32 = static_cast<std::uint32_t>(::crc32(0L, reinterpret_cast<const Bytef*>(raw.data()), static_cast<uInt>(raw.size())));

  if (raw.empty()) {
    outCompressed.clear();
    return true;
  }

  uLongf destLen = ::compressBound(static_cast<uLong>(raw.size()));
  outCompressed.resize(destLen);

  z_stream stream{};
  stream.zalloc = Z_NULL;
  stream.zfree = Z_NULL;
  stream.opaque = Z_NULL;

  // Step 2: Initialize zlib deflate stream with -MAX_WBITS for raw DEFLATE format
  if (deflateInit2(&stream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -MAX_WBITS, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
    return false;
  }

  stream.next_in = reinterpret_cast<Bytef*>(const_cast<char*>(raw.data()));
  stream.avail_in = static_cast<uInt>(raw.size());
  stream.next_out = reinterpret_cast<Bytef*>(outCompressed.data());
  stream.avail_out = static_cast<uInt>(destLen);

  int res = deflate(&stream, Z_FINISH);
  deflateEnd(&stream);

  if (res != Z_STREAM_END) {
    return false;
  }

  outCompressed.resize(stream.total_out);
  return true;
}

/**
 * Adds an in-memory string payload file to the ZIP archive entries.
 */
bool ZipWriter::addFile(const std::string &archivePath, const std::string &content) {
  Entry entry;
  entry.filename = archivePath;
  entry.uncompressedSize = static_cast<std::uint32_t>(content.size());
  getDosTimeDate(entry.dosTime, entry.dosDate);

  if (!compressData(content, entry.compressedData, entry.crc32)) {
    return false;
  }
  entry.compressedSize = static_cast<std::uint32_t>(entry.compressedData.size());
  entries_.push_back(std::move(entry));
  return true;
}

/**
 * Adds a physical disk file payload to the ZIP archive entries.
 */
bool ZipWriter::addFileFromDisk(const std::string &archivePath, const std::filesystem::path &filePath) {
  std::ifstream in(filePath, std::ios::binary);
  if (!in) return false;
  std::string content((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
  in.close();
  return addFile(archivePath, content);
}

/**
 * Writes standard PKWARE ZIP binary layout to target file path.
 * Writes Local File Headers (0x04034b50), Central Directory (0x02014b50), and EOCD (0x06054b50).
 */
bool ZipWriter::writeToFile(const std::filesystem::path &outputPath) {
  std::ofstream out(outputPath, std::ios::binary);
  if (!out) return false;

  std::uint32_t currentOffset = 0;

  // Step 1: Write Local File Headers and compressed file data
  for (auto &entry : entries_) {
    entry.localHeaderOffset = currentOffset;

    std::uint32_t sig = 0x04034b50;
    std::uint16_t versionNeeded = 20;
    std::uint16_t flags = 0;
    std::uint16_t method = entry.compressionMethod;
    std::uint16_t filenameLen = static_cast<std::uint16_t>(entry.filename.size());
    std::uint16_t extraLen = 0;

    out.write(reinterpret_cast<const char*>(&sig), 4);
    out.write(reinterpret_cast<const char*>(&versionNeeded), 2);
    out.write(reinterpret_cast<const char*>(&flags), 2);
    out.write(reinterpret_cast<const char*>(&method), 2);
    out.write(reinterpret_cast<const char*>(&entry.dosTime), 2);
    out.write(reinterpret_cast<const char*>(&entry.dosDate), 2);
    out.write(reinterpret_cast<const char*>(&entry.crc32), 4);
    out.write(reinterpret_cast<const char*>(&entry.compressedSize), 4);
    out.write(reinterpret_cast<const char*>(&entry.uncompressedSize), 4);
    out.write(reinterpret_cast<const char*>(&filenameLen), 2);
    out.write(reinterpret_cast<const char*>(&extraLen), 2);
    out.write(entry.filename.data(), filenameLen);

    if (!entry.compressedData.empty()) {
      out.write(reinterpret_cast<const char*>(entry.compressedData.data()), entry.compressedData.size());
    }

    currentOffset += static_cast<std::uint32_t>(30 + filenameLen + entry.compressedData.size());
  }

  std::uint32_t cdOffset = currentOffset;
  std::uint32_t cdSize = 0;

  for (const auto &entry : entries_) {
    std::uint32_t sig = 0x02014b50;
    std::uint16_t versionMadeBy = 20;
    std::uint16_t versionNeeded = 20;
    std::uint16_t flags = 0;
    std::uint16_t method = entry.compressionMethod;
    std::uint16_t filenameLen = static_cast<std::uint16_t>(entry.filename.size());
    std::uint16_t extraLen = 0;
    std::uint16_t commentLen = 0;
    std::uint16_t diskStart = 0;
    std::uint16_t intAttr = 0;
    std::uint32_t extAttr = 0;

    out.write(reinterpret_cast<const char*>(&sig), 4);
    out.write(reinterpret_cast<const char*>(&versionMadeBy), 2);
    out.write(reinterpret_cast<const char*>(&versionNeeded), 2);
    out.write(reinterpret_cast<const char*>(&flags), 2);
    out.write(reinterpret_cast<const char*>(&method), 2);
    out.write(reinterpret_cast<const char*>(&entry.dosTime), 2);
    out.write(reinterpret_cast<const char*>(&entry.dosDate), 2);
    out.write(reinterpret_cast<const char*>(&entry.crc32), 4);
    out.write(reinterpret_cast<const char*>(&entry.compressedSize), 4);
    out.write(reinterpret_cast<const char*>(&entry.uncompressedSize), 4);
    out.write(reinterpret_cast<const char*>(&filenameLen), 2);
    out.write(reinterpret_cast<const char*>(&extraLen), 2);
    out.write(reinterpret_cast<const char*>(&commentLen), 2);
    out.write(reinterpret_cast<const char*>(&diskStart), 2);
    out.write(reinterpret_cast<const char*>(&intAttr), 2);
    out.write(reinterpret_cast<const char*>(&extAttr), 4);
    out.write(reinterpret_cast<const char*>(&entry.localHeaderOffset), 4);
    out.write(entry.filename.data(), filenameLen);

    cdSize += static_cast<std::uint32_t>(46 + filenameLen);
  }

  std::uint32_t eocdSig = 0x06054b50;
  std::uint16_t diskNum = 0;
  std::uint16_t cdDiskNum = 0;
  std::uint16_t totalEntries = static_cast<std::uint16_t>(entries_.size());
  std::uint16_t commentLen = 0;

  out.write(reinterpret_cast<const char*>(&eocdSig), 4);
  out.write(reinterpret_cast<const char*>(&diskNum), 2);
  out.write(reinterpret_cast<const char*>(&cdDiskNum), 2);
  out.write(reinterpret_cast<const char*>(&totalEntries), 2);
  out.write(reinterpret_cast<const char*>(&totalEntries), 2);
  out.write(reinterpret_cast<const char*>(&cdSize), 4);
  out.write(reinterpret_cast<const char*>(&cdOffset), 4);
  out.write(reinterpret_cast<const char*>(&commentLen), 2);

  out.close();
  return true;
}

}  // namespace server::utils
