# NSRL-NIST-utility
This repository includes a basic script to be used with Workstation/console.

# Prerequisites
Install the redis Gem if you wish to export to REDIS, otherwise disregard
```
cd c:\Program Files\Nuix\Nuix 9.10
jre\bin\java -Xmx500M -classpath lib\* org.jruby.Main --command gem install redis --user-install
```

# Configure where the database file is
The file contains these lines. Set the db path as the location to the extracted sqlite3 database for example:

```
dbpath="C:\\Users\\cstiller01\\Downloads\\RDS_2023.03.1_modern_minimal\\RDS_2023.03.1_modern_minimal.db"
```

# Export to Nuix.hash

If you want to export only a Nuix hash adjust it like so:
```
options={
  "file"=>"C:/temp/modern_minimal.hash",
  "tallyStep"=> 100000
}
```

# Export to REDIS

If you'd like to export to REDIS adjust it like so, be sure to update with your appropriate credentials.

Warning: bufferSize has been tested to optimally sit around the 500,000 area. Any more than that tends to create timeouts. 

Set verify=>true if you wish to confirm the submissions are going through.

```
options={
  "redis"=>{
    "password"=>"yourpassword",
    "host"=>"10.10.12.104",
    "port"=>"6379",
    "verify"=>false,
    "bufferSize"=>500000,
    "buffer" => Array.new
  },
  "tallyStep"=> 100000
}
```

# Export to both REDIS and file

```
options={
  "file"=>"C:/temp/modern_minimal.hash",
  "redis"=>{
    "password"=>"yourpassword",
    "host"=>"10.10.12.104",
    "port"=>"6379",
    "verify"=>false,
    "bufferSize"=>500000,
    "buffer" => Array.new
  },
  "tallyStep"=> 100000
}
```
