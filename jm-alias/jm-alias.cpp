#include <unistd.h>

#include <algorithm>
#include <list>
#include <filesystem>
#include <format>
#include <iostream>
#include <map>
#include <optional>
#include <print>
#include <ranges>
#include <string>
#include <string_view>
#include <vector>

using namespace std;

map<string,tuple<string, vector<string>>> aliases{
  {":q", {"exit", {}}},
  {"b",  {"buildah", {}}},
  {"g",  {"git", {}}},
  {"gr", {"grep", {}}},
  {"d",  {"docker", {}}},
  {"dc", {"docker-compose", {}}},
  {"l",  {"ls", {}}},
  {"ll", {"ls", {"-l"}}},
  {"grr", {"grep", {"-r", "--exclude", "tags", "--exclude-dir=.git", "--exclude-dir=.tox"}}},
  {"p",  {"podman", {}}},
  {"pc", {"podman-compose", {}}},
  {"s",  {"systemctl", {}}},
  {"t",  {"tmux", {}}},
  {"gr_video", {"grep", {"-iE", "(avi|flv|mkv|wmv|mpg|mpeg|mp4)"}}},
  {"gr_pics", {"grep", {"-iE", "(jpg|jpeg|tiff|bmp|png|gif)"}}},
};

void to_lower_inplace(char& c) {
  c = (char)tolower(c);
}

bool boolish(char* x) {
  if(!x)
    return false;

  string s(x);
  for_each(s.begin(), s.end(), to_lower_inplace);
  return (s == "on" || s == "1" || s == "true");
}

class BaseLog {
public:
  template <typename... T>
  void verbose(format_string<T...> fmt, T&& ...args) {
    string msg = vformat(fmt.get(), make_format_args(args...));
    _verbose(msg);
  }

  virtual void _verbose(string msg) {
  }
};

class Log : public BaseLog {
public:
  virtual void _verbose(string msg) {
    cerr << msg << endl;
  }
};

BaseLog* _log = new BaseLog();

optional<string> which(
  string name,
  optional<const filesystem::path> skip
) {
  char* c_path = getenv("PATH");
  if(!c_path)
    return nullopt;

  using filesystem::perms;
  for(const auto& v_path: views::split(string(c_path), ':')) {
    filesystem::path p{string_view(v_path)};
    p /= name;

    _log->verbose("checking {}", string(p));

    if(!(exists(p) && (is_regular_file(p) || is_symlink(p)))) {
        _log->verbose("  failed existence check", string(p));

      continue;
    }

    auto path_canon = filesystem::canonical(p);
    if (skip.has_value() and skip.value() == path_canon) {
      _log->verbose("  skip due to match with skip argument");
      continue;
    }

    auto ps = filesystem::status(p).permissions();
    if (!(
      perms::none != (ps & perms::owner_exec)
      || perms::none != (ps & perms::group_exec)
      || perms::none != (ps & perms::others_exec)
    )) {
        _log->verbose("  failed permissions passed");
      continue;
    }

    return p;
  }

  return nullopt;
}

int ls_aliases() {
  for(const auto &[key, ignore]: aliases) {
    cout << format("{}\n", key);
  }
  return 0;
}

int dispatch(
  const string& name,
  vector<char*> args,
  const filesystem::path& self
) {
  if(!aliases.contains(name)) {
    println(cerr, "jm-alias: {}: alias not found", name);
    return 1;
  }

  auto target = aliases.at(name);
  auto target_name = get<0>(target);
  auto path = which(target_name, self);
  if (!path) {
    println(cerr, "jm-alias: {}: command not found", target_name);
    return 1;
  }

  auto xs = get<1>(target);
  args.reserve(args.size() + xs.size());
  reverse(xs.begin(), xs.end());
  for(auto& x: xs) {
    args.insert((args.begin()+1), const_cast<char*>(x.c_str()));
  }
  args.push_back(nullptr);

  if(-1 == execv(path.value().c_str(), args.data()))
    perror("jm-alias: execv() failed");

  return 1;
}


class Cmd {
public:
  const filesystem::path cmd;

  Cmd(const filesystem::path cmd) : cmd(cmd) {}

  filesystem::path self() {
    auto with_path = which(cmd, nullopt);
    if (!with_path.has_value())
      throw runtime_error("jm-util: couldn't find self in PATH");

    const filesystem::path self = filesystem::canonical(with_path.value());
    return self;
  }

  const string name() {
    return cmd.filename();
  }
};

int main(const int argc, char** argv) {
  if(boolish(getenv("JMU_ALIAS_VERBOSE")))
    _log = new Log();

  vector<char*> args;
  for (int i=0; i<argc; i++) {
    args.push_back(argv[i]);
  }

  auto cmd = Cmd(args[0]);

  if (cmd.name() == "jm-alias")
    return ls_aliases();
  else
    return dispatch(cmd.name(), args, cmd.self());
}
