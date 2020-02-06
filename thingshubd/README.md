# thingshubd

A launchctl job to sync thingshub for your selected projects a few times a day.

## Installation

Run `make install`.

## Usage

Edit the file `~/.local/thingshubd.list` to include a list of directories. Each directory must contain `.thingshubconfig` files, or at least the command `thingshub` must do something sensible when run in each directory. You can use a isngle variable, `$HOME`, in this file.

Test via `make run`.
