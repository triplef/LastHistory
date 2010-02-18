LastHistory
===========
LastHistory allows you to analyze music listening histories from [Last.fm](http://www.last.fm) through an interactive visualization and to explore your own past by combining the music you listened to with your own photos and calendar entries. It is written as a desktop application for Mac OS X 10.5 or higher.

LastHistory can be used in one of two modes, each of which is optimized for a different use case:

* **Analysis Mode**  
  This mode can be used for interactively analyzing an arbitrary listening history (not necessarily your own) in three basic dimensions: time, tracks and genre. Integrated tools like searching, playlist highlighting, mouse-over information, and zooming allow to generate insight for the visualized music listening history in each of those dimensions.

* **Personal Mode**  
  This mode adapts the visualization shown in Analysis mode for exploring your own past: by adding photos from your iPhoto library and calendar entries from iCal to the visualization, you can reminisce about your past by listening to the top tracks from your last vacation while watching a slide show of the corresponding photos. Or you can find the most influential tracks that you listened to most during a specific timeframe by inspecting the highlighted tracks in the visualization.

System Requirements
-------------------
Mac OS X v10.5 or later. Intel processor with 2.2 GHz or more and 256 MB VRAM or more recommended.  
LastHistory has been tested with listening histories up to 125000 entries on a MacBook Pro 2.53GHz. While there is no general limit on the size of the listening history, the bigger the history the more resources the program needs (in particular CPU and VRAM).

Source Code
-----------
LastHistory is written in Objective-C/Cocoa with extensive use of Apple's [Core Data](http://developer.apple.com/mac/library/referencelibrary/GettingStarted/GettingStartedWithCoreData/index.html) and [Core Animation](http://developer.apple.com/mac/library/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html) frameworks. The Xcode project uses [mogenerator](http://rentzsch.github.com/mogenerator/) for generating classes for the Core Data custom classes. Make sure to install mogenerator 1.16 or higher before editing the data model.

License
-------
© 2010 Frederik Seiffert <<ego@frederikseiffert.de>>.  
LastHistory is licensed under a [Creative Commons GNU General Public License License](http://creativecommons.org/licenses/GPL/2.0/).
