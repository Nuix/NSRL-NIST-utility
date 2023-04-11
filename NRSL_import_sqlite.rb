require 'java'
java_import java.sql.DriverManager
java_import java.sql.Connection
java_import java.sql.ResultSet
java_import java.sql.SQLException
java_import java.sql.Statement
java.sql.DriverManager.registerDriver(org.sqlite.JDBC.new())

dbpath="C:\\Users\\cstiller01\\Downloads\\RDS_2023.03.1_modern_minimal\\RDS_2023.03.1_modern_minimal.db"


options={
  "file"=>"C:/temp/modern_minimal.hash",
  "redis"=>{
    "password"=>"P@55w0rd",
    "host"=>"10.10.12.104",
    "port"=>"6379",
	"verify"=>false,
    "bufferSize"=>500000,
    "buffer" => Array.new
  },
  "tallyStep"=> 100000
}

if(!((options.has_key? 'redis') || (options.has_key? 'file')))
  puts "redis or file is required... otherwise this is not going to do very much is it"
  exit
end

if(options.has_key? 'redis')
    begin
      require 'redis'
    rescue Exception => ex
      puts ex.message
      puts "Looks like you don't have redis gem? Install with:\ncd c:\\Program Files\\Nuix\\Nuix 9.10\njre\\bin\\java -Xmx500M -classpath lib\\* org.jruby.Main --command gem install redis --user-install"
    end
end

begin
  if(!(File.exists? dbpath))
    puts "Database does not exist at this path:#{dbpath}"
    exit
  end
  begin
    dbconnection=java.sql.DriverManager.getConnection("jdbc:sqlite:#{dbpath}")
  rescue => sqlEx
    puts sqlEx.message
    puts sqlEx.backtrace
    exit
  end
  puts "Querying database... stand by, this can take a while"
  stmt=dbconnection.create_statement
  rs = stmt.executeQuery("SELECT DISTINCT md5 FROM FILE")
  puts "Results queried... Iterating the results..."
  #At this point we have the database opened it seems.. so it's good to start writing out
  if(options.has_key? "redis")
    #SET UP CONNECTION TO REDIS INSTANCE
    begin
      redis = Redis.new(:host => options['redis']['host'], :port => options['redis']['port'].to_i, :password => options['redis']['password'], :timeout => 300) # 3 minute timeout
      if(redis.ping != "PONG")
        redis=nil
      end
    rescue Exception => ex
      puts "REDIS could not be contacted...."
      puts ex.message
      puts ex.backtrace
    end
  end
  if(options.has_key? "file")
    file=File.open(options['file'],"wb")
    #Headers
    file.write("F2DL")
    file.write([1].pack('N'))
    file.write([3].pack('n'))
    file.write("MD5")
  end
  tally=0
  verified=0
  while(rs.next) do 
    row=Hash.new()
    friendlyMD5=rs.getString(1).gsub(/[^a-fA-F0-9]/,'')
    if(!(file.nil?))
      file.write([friendlyMD5].pack('H*')) #friendly to binary
    end
    if(!(redis.nil?))
      options['redis']['buffer'] << friendlyMD5.downcase
      if(options['redis']['buffer'].size >= options['redis']['bufferSize'])
	    puts "\tSubmitting batch"
		redis.sadd("nsrl", options['redis']['buffer'])
		if(options['redis']['verify']==true)
			puts "\tverifying..."
			results=redis.smismember("nsrl", options['redis']['buffer']).select{|m|m==true}.size()
			verified=verified+results
		end
        options['redis']['buffer']=Array.new
      end
    end
    tally=tally+1
    if(tally % options['tallyStep']==0)
      puts "Read: #{tally}, Verified: #{verified}"
    end
  end
rescue Exception => ex
  puts ex.message
  puts ex.backtrace
ensure
  if(dbconnection)
    dbconnection.close()
  end
  if(!(file.nil?))
    file.close()
  end
  if(!(redis.nil?))
    if(options['redis']['buffer'].size > 1)
      redis.sadd("nsrl", options['redis']['buffer'])
		puts "\tSubmitting batch"
        redis.sadd("nsrl", options['redis']['buffer'])
		if(options['redis']['verify']==true)
			puts "\tverifying..."
			results=redis.smismember("nsrl", options['redis']['buffer']).select{|m|m==true}.size()
			verified=verified+results
		end
		puts "Read: #{tally}, Verified: #{verified}"
    end
	redis.quit
  end
end

