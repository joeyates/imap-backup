# Installation From Source

In order to run imap-backup from source, you'll need Ruby and [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git).

Next, clone the repository

```sh
git clone https://github.com/joeyates/imap-backup.git
cd imap-backup
```

If you want to use a branch other than `main`

```sh
git checkout --track -b BRANCH origin/BRANCH
```

Install dependencies

```sh
gem install bundler --version=2.3.22
bundle install
```

Check that it runs

```sh
bin/imap-backup help
```
