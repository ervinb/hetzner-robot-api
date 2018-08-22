# [WIP] Hetzner Robot API wrapper
[![Build
Status](https://semaphoreci.com/api/v1/ervinb/hetzner-robot-api/branches/master/badge.svg)](https://semaphoreci.com/ervinb/hetzner-robot-api)

CLI tool which provides convenience methods to manage Hetzner servers through
their [API](https://robot.your-server.de/doc/webservice/en.html).

## Usage

Run `bin/console` and read the instructions below.


### Initiating a connection to Hetzner

Authenticate to Hetzner.

```
client = HetznerRobotApi::Client.new "username", "password"
```

TODO: read credentials from a config file or the ENV


### Server management

Once the client is created, the server manager instance can be used to perform
actions on the servers.

```
pry(main)> client = HetznerRobotApi::Client.new "username", "password"
pry(main)> sm = HetznerRobotApi::ServerManager.new(client)
```

The section below describes what actions can be performed with the server
manager.

#### Querying servers

Servers can be queried based on all the [available
fields](https://robot.your-server.de/doc/webservice/en.html#server) on Hetzner:
- `server_ip`
- `server_number`
- `server_name`
- `product`
- `dc`
- `traffic`
- `flatrate`
- `status`
- `throttled`
- `cancelled`
- `paid_until`

The fields are handled dynamically, so if Hetzner introduces a new
one, no change is needed -- it can be used right away.

```
# Fetch all servers which have a blank name and are of type EX41S-SSD
pry(main)> servers = sm.fetch_server_list(:filters => {:server_name => "", :product => "EX41S-SSD"})

=> [#<OpenStruct server=#<OpenStruct
     server_ip="12.34.56.78",
     server_number=797382,
     server_name="",
     product="EX41S-SSD",
     dc="FSN1-DC8",
     traffic="30 TB",
     flatrate=true,
     status="ready",
     throttled=false,
     cancelled=false,
     paid_until="2018-01-22">>,
   #<OpenStruct server=#<OpenStruct
     server_ip="12.34.56.79",
     server_number=797536,
     server_name="",
     product="EX41S-SSD",
     dc="FSN1-DC1",
     traffic="30 TB",
     flatrate=true,
     status="ready",
     throttled=false,
     cancelled=false,
     paid_until="2018-01-22">>
   ]
```

This raw `OpenStruct` array can be accessed with `sm.server_list`.

Queries also support wildcards `?` and `*` in any of the fields.

```
# fetch all servers from the EX line
pry(main)> servers = sm.fetch_server_list(:filters => {:product => "EX?"})
```


#### Print servers as a formatted table

After a query, servers can be displayed as a table. This is most suitable for
human use.


```
pry(main)> sm.print_server_table
-------------------------------------------------------------------------------------------------------------------------------
 server_ip        server_number  server_name  product    dc        traffic  flatrate  status  throttled  cancelled  paid_until
-------------------------------------------------------------------------------------------------------------------------------
 12.34.56.78      797382         bx87         EX41S-SSD  FSN1-DC8  30 TB    true      ready   false      false      2018-01-22
 12.34.56.79      797536         bx88         EX41S-SSD  FSN1-DC1  30 TB    true      ready   false      false      2018-01-22
-------------------------------------------------------------------------------------------------------------------------------
```

By default, all available fields are shown, but this can be customized, by
using an array of field names as a parameter:

```
pry(main)> sm.print_server_table(["server_ip", "server_name"])
------------------------------
 server_ip        server_name
------------------------------
 12.34.56.78      bx87
 12.34.56.79      bx88
------------------------------
```

#### Print server list in various formats

A server list can be produced in the following formats:
- `:yaml`
- `:json`
- `:list`

Each can be further customized, by defining which fields will be printed.
By default the `server_ip` field is shown, and the format is `:yaml`.

```
pry(main)> puts sm.server_list_to_format
---
servers:
- bx87:
    server_ip: 12.34.56.78
- bx88:
    server_ip: 12.34.56.79
```


As JSON:

```
pry(main)> puts sm.server_list_to_format
{"servers":[{"bx87":{"server_ip":"12.34.56.78"}},{"bx88":{"server_ip":"12.34.56.79"}}]}
```


As a plain list:

```
pry(main)> puts sm.server_list_to_format(:format => :list)
12.34.56.78
12.34.56.79
```

Print multiple fields:

```
pry(main)> puts sm.server_list_to_format(:fields => [:server_ip, :dc])
---
servers:
- bx50:
  server_ip: 138.201.131.94
  dc: FSN1-DC8
```
Note that the `:list` format prints only the first field, and the default is
`:server_ip`.


#### Renaming servers

Server can be renamed in batch.

```
pry(main)> sm.update_server_names(:prefix => "bx", :start_number => 87)
```

This will rename all servers from `sm.server_list`, by doing `"<prefix><start_number(+1)>"`.

```
sm.update_server_names(:prefix => "bx", :start_number => 87)
# eg if the query has 2 servers, the function names the servers "bx87" and "bx88"
```

#### Cancelling servers

Mass cancellation of the queried servers.

By default, the earliest cancellation date is selected, but it can be postponed by defining a later date with `:cancellation_date => <Date>`.

```
pry(main)> sm.cancel_servers(:cancellation_date => '2017-03-14')
```

#### Rebooting servers

[WIP] No convenience method yet. To reboot the queried servers:
```
pry(main)> sm.server_list.each {|entry| ip = entry.server.server_ip.gsub(/\./, "_"); puts "Operating status for [#{ip}]: #{client.reset.send(ip.to_sym).get}"};
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/hetzner_robot_api.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

