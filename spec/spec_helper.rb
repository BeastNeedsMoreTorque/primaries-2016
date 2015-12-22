# rspec adds lib/ to the $LOAD_PATH, but we have a 'logger' in lib/ that
# masks Ruby's default 'logger'.
#
# https://github.com/rspec/rspec-core/issues/1983
$LOAD_PATH.delete_if { |p| File.expand_path(p) == File.expand_path('./lib') }
