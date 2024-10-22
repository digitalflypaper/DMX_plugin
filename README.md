This Brightsign plugin works with the DMX interface designed by Digital Flypaper to work with Brightsign devices.  The unit will also work with any device that can send commands to a USB serial device

The plugin reads a "track" file with the same name as the matching video file but with a ".dmx" extension. For example, myVideo.mp4 will need a track file named myVideo.dmx.

The .dmx file is a JSON file with the following format:


{
   "filename":"video_file_name.mp4",
   "timedata":
   [
       {
           "time_sec":"0",
           "tag":"1:0,2:123"
       },
       {
           "time_sec":"0.83215",
           "tag":"2:222"
       },
       ..
       ..
       {
           "time_sec":"118.010515",
           "tag":"1:0"
       }
   ]
 }


 
 
