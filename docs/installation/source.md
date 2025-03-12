<!--
# @title installation: from source
-->
# Installation From Source

In order to run imap-backup from source, you'll need [Ruby](https://www.ruby-lang.org/en/documentation/installation/) and [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

Next, clone the repository:

```sh
git clone https://github.com/joeyates/imap-backup.git
```

If you want to use a branch other than `main`:

```sh
git checkout --track -b BRANCH origin/BRANCH
```

Install dependencies:

```sh
cd imap-backup
gem install bundler --version=2.3.22
bundle install
```

Check that it runs:

```sh
bin/imap-backup version
```

If you get something like

```
imap-backup 14.4.4
```
congratulations, you have succesfully built imap-backup.

You ca now run the following to see the built-in help:

```sh
bin/imap-backup help
```
