# GRM — Git Repository Manager

GRM helps you manage git repositories in a declarative way. Configure your
repositories in a [TOML](https://toml.io/) file, GRM does the rest.

## Quickstart

See [the example configuration](example.config.toml) to get a feel for the way
you configure your repositories.

### Install

```bash
$ cargo install --git https://github.com/hakoerber/git-repo-manager.git --branch master
```

### Get the example configuration

```bash
$ curl --proto '=https' --tlsv1.2 -sSfO https://raw.githubusercontent.com/hakoerber/git-repo-manager/master/example.config.toml
```

### Run it!

```bash
$ grm sync --config example.config.toml
[⚙] Cloning into "/home/me/projects/git-repo-manager" from "https://code.hkoerber.de/hannes/git-repo-manager.git"
[✔] git-repo-manager: Repository successfully cloned
[⚙] git-repo-manager: Setting up new remote "github" to "https://github.com/hakoerber/git-repo-manager.git"
[✔] git-repo-manager: OK
[⚙] Cloning into "/home/me/projects/dotfiles" from "https://github.com/hakoerber/dotfiles.git"
[✔] dotfiles: Repository successfully cloned
[✔] dotfiles: OK
```

If you run it again, it will report no changes:

```
$ grm sync --config example.config.toml
[✔] git-repo-manager: OK
[✔] dotfiles: OK
```

### Generate your own configuration

Now, if you already have a few repositories, it would be quite laborious to write
a configuration from scratch. Luckily, GRM has a way to generate a configuration
from an existing file tree:

```bash
$ grm find ~/your/project/root > config.toml
```

This will detect all repositories and remotes and write them to `config.toml`.

### Show the state of your projects

```bash
$ grm status --config example.config.toml
+------------------+------------+----------------------------------+--------+---------+
| Repo             | Status     | Branches                         | HEAD   | Remotes |
+=====================================================================================+
| git-repo-manager |            | branch: master <origin/master> ✔ | master | github  |
|                  |            |                                  |        | origin  |
|------------------+------------+----------------------------------+--------+---------|
| dotfiles         | No changes | branch: master <origin/master> ✔ | master | origin  |
+------------------+------------+----------------------------------+--------+---------+
```

You can also use `status` without `--config` to check the current directory:

```
$ cd ./dotfiles
$ grm status
+----------+------------+----------------------------------+--------+---------+
| Repo     | Status     | Branches                         | HEAD   | Remotes |
+=============================================================================+
| dotfiles | No changes | branch: master <origin/master> ✔ | master | origin  |
+----------+------------+----------------------------------+--------+---------+
```

### Manage worktrees for projects

Optionally, GRM can also set up a repository to support multiple worktrees. See
[the git documentation](https://git-scm.com/docs/git-worktree) for details about
worktrees. Long story short: Worktrees allow you to have multiple independent
checkouts of the same repository in different directories, backed by a single
git repository.

To use this, specify `worktree_setup = true` for a repo in your configuration.
After the sync, you will see that the target directory is empty. Actually, the
repository was bare-cloned into a hidden directory: `.git-main-working-tree`.
Don't touch it! GRM provides a command to manage working trees.

Use `grm worktree add <name>` to create a new checkout of a new branch into
a subdirectory. An example:

```bash
$ grm worktree add mybranch
$ cd ./mybranch
$ git status
On branch mybranch

nothing to commit, working tree clean
```

If you're done with your worktree, use `grm worktree delete <name>` to remove it.
GRM will refuse to delete worktrees that contain uncommitted or unpushed changes,
otherwise you might lose work.

# Why?

I have a **lot** of repositories on my machines. My own stuff, forks, quick
clones of other's repositories, projects that never went anywhere ... In short,
I lost overview.

To sync these repositories between machines, I've been using Nextcloud. The thing
is, Nextcloud is not too happy about too many small files that change all the time,
like the files inside `.git`. Git also assumes that those files are updated as
atomically as possible. Nextcloud cannot guarantee that, so when I do a `git status`
during a sync, something blows up. And resolving these conflicts is just no fun ...

In the end, I think that git repos just don't belong into something like Nextcloud.
Git is already managing the content & versions, so there is no point in having
another tool do the same. But of course, setting up all those repositories from
scratch on a new machine is too much hassle. What if there was a way to clone all
those repos in a single command?

Also, I once transferred the domain of my personal git server. I updated a few
remotes manually, but I still stumble upon old, stale remotes in projects that
I haven't touched in a while. What if there was a way to update all those remotes
in once place?

This is how GRM came to be. I'm a fan of infrastructure-as-code, and GRM is a bit
like Terraform for your local git repositories. Write a config, run the tool, and
your repos are ready. The only thing that is tracked by git it the list of
repositories itself.

# Future & Ideas

* Operations over all repos (e.g. pull)
* Show status of managed repositories (dirty, compare to remotes, ...)

# Optional Features

* Support multiple file formats (YAML, JSON).
* Add systemd timer unit to run regular syncs

# Dev Notes

It requires nightly features due to the usage of [`std::path::Path::is_symlink()`](https://doc.rust-lang.org/std/fs/struct.FileType.html#method.is_symlink). See the [tracking issue](https://github.com/rust-lang/rust/issues/85748).

# Crates

* [`toml`](https://docs.rs/toml/) for the configuration file
* [`serde`](https://docs.rs/serde/) because we're using Rust, after all
* [`git2`](https://docs.rs/git2/), a safe wrapper around `libgit2`, for all git operations
* [`clap`](https://docs.rs/clap/), [`console`](https://docs.rs/console/) and [`shellexpand`](https://docs.rs/shellexpand) for good UX

# Links

* [crates.io](https://crates.io/crates/git-repo-manager)
