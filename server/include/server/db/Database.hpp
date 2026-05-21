#pragma once

#include <sqlite3.h>

#include <optional>
#include <string>

namespace server::db {

class Database {
 public:
  explicit Database(const std::string &path);
  ~Database();

  Database(const Database &) = delete;
  Database &operator=(const Database &) = delete;

  sqlite3 *raw() const { return db_; }

  void migrate();

 private:
  sqlite3 *db_{nullptr};
  void exec(const std::string &sql);
};

}  // namespace server::db
