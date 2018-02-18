(make sure to have the temp directories creating during 'edit
 page(s)' not collide with existing documents)



(somethings to do 
 (create the ability to find a document in the inventory
  management system using a cell phone camera picture of it)
 (have the inventory management store the location of each piece
  of paper.  When splitting a document into pages or multiple
  images per page, default to placing all the new documents to
  where the original one was, for instance if it was in the main
  box in the yellow folder, then put the new ones there too (by
  default, have the option to override).)

 (use git to have undo features.)
 (if we shred a document that we've scanned, note that.  if we've
  thrown it away, note that.)
 (have a dialog at the end of scanning which asks what we did with the
  originals
  (shredded, thrown out, stored in particular place, unknown,
   etc)
  )
 (start working on the user document for paperless office)

 (use an inventory management system which is independent of
  paperless office - user the WSM/normal form, etc, with maybe
  plugins to handle the documents.)


 
 
 (add a read document with clear feature)
 (have it have the ability to move selected documents, not just
  the one selected by the mouse)
 (have it deselect any individual document it moves)
 (enable the user to click on the canvas to completely deselect)
 (change Actions->Edit to Actions->'Edit Image(s)' and add Actions->'Edit Page(s)')
 (put some kind of authentication in for editing page images and other severe edit commands)
 (have a rotate page function)
 (have the ability to distinguish the number of pages on a
  document from the overview page)
 (have the ability to edit all the pages of a document)
 (have the ability to split a document into some subset of it's pages)
 (have the ability to edit multiple documents at a time, and join parts of them)
 (have the ability to label two images as being opposite sides of
  the same piece of paper)
 
 (have the ability to split a single (or hopefully, multiple)
  image(s) into multiple pages, and or documents)

 (get it so that when we 'cancel' or click on the exit for a
  given window like 'Actions'->'Modify Folders', that we can then
  relaunch it and it will come up again.)
 (implement a button on 'Actions'->'Modify Folders' that allows
  one to add a new folder to the list)
 (add items to the normal-form/inform7 stuff to record/document
  the layout of the upstairs computer room, especially as it
  relates to the function of each of the containers etc.)
 (add a property "in use" vs. "not in use" to cables in order to
  allow us to specify that the default location for cables 'not in
  use' is in that box in the upstairs computer room.  Please note,
  should have a distinction for a cable that is on standby which
  is left plugged in waiting for the time at which it is
  habitually used, such as the cable that powers the headset)
 (read about all the other features to add to paperless office,
  and work to add them now) 
 (add ability to mark certain pages as front and back etc types
  of collation during scanning)
 ()
 (add something that says that on a certain day we can use a
  certain promotion - automatically extract the expiration dates
  on coupons, link to broker heheh)
 (add a rename folder function)

 )

(to backup, first run the backup of neat (for all folders), then
 run backup of paperless-office (File->Backup), copy those files
 to
 /var/lib/myfrdcsa/codebases/minor/paperless-office/data/secure-document-backup/,
 then run

 /var/lib/myfrdcsa/codebases/minor/paperless-office/scripts/backup-secure-documents.pl)

(paperless office should dump the contents of the kbs into a file
 and then sync everything using git, and backup to a remote site
 using push/pull, for version control.)

(have remote access to all documents)

(add thing to paperless office which is the decision of what to
 do with a given document) 
(use flora-2 to handle the logic of the paperless office
 /var/lib/myfrdcsa/codebases/minor/paperless-office/model.flr
 )


(write a guide for how to manage a giant pile of papers,
 receipts, etc that you need to go through for finances etc, and
 to get on top of a messy life
 (locate tutorials that provide ideas etc
  (look at life planner library of howtos
   (get additional specific how tos for paperwork)
   )
  )
 )

(Write a system that works with android that communicates with
 the AI and tells it when there is a loan or a purchase.
 (check into existing stuff)
 (sell this system)
 (make it work with GnuCash, PaperlessOffice)
 (rename paperless-office)

 (Read marketing book and develop "business plan" i.e. "marketing
  plan" for paperless office and the rest of the FRDCSA.)
 
 )

(add the following to the systems:
 (an rsync backup mechanism, configured in the configuration)
 (put scanners in a tab after view, without causing the display
  that happens during scanning to not work)
 (eventually write tests)
 (add the ability to quickly fix orientation)
 (add encryption)
 (add better OCR)
 (add compression to images)
 (add ability to segment, pair, mark as opposite sides of the same paper, etc)
 (fix the titles all being 0)

 )



(resize the files automatically at scan time to save room)

(to shrink the pdf size
(gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=dental.pdf Dental_Vision_Combo_EE_App-Andrew-J-Dougherty.pdf ))



(have a function (find all documents/pages that differ only
		  slightly from a given document/page))


(to fix the calendar generation
 (need to ensure that $self->Events is populated)
 (need to fix line wrap issue)
 (need to iterate over all months and years desired)
 (need to improve the fidelity)
 (need to eliminate the extra date item or not)
 (need to eliminate all the dumping)
 )








(some more ideas
 (have the ability to label a document as requiring an expert to
  review it) 
 )

(improve the search capabilities)

(some ideas here
 (have the ability to say that a given document needs to be given
  by hand, mailed or emailed, etc to a certain person or address...)

 (Face recognition, tagging with metadata.  Object recognition.
  Geolocation tagging.  All modern features.  KB indexing.  Show
  all photos of Dutch.)

 (have the ability to scan in photos
  (write a tutorial and a video on how to do this)
  (have a workflow that helps get the best images)
  (have the option of selecting photo scan and different resolutions)
  (have that image splitter program)
  (clean the surface of the images using a towelette or
   something)
  (scan them, allowing enough space in between for image segmentation)
  (automatically segment, ?rotate? and "software dust-bust" them
   before creating items for them - then add them as individual
   photos)
  (share the collection with others using the paperless-office system)
  (store them in a thing called photos)
  (allow annotations)
  (have this one of the special modes)
  (mark the back of the images some kind of stamp)
  )

 (create video instruction for the whole system, showing how to
  scan documents, and how to organize your filing cabinets, etc.
  (The video should be shot in segments and rendered from
   workflows.  that way, any adjustment of the script material,
   such as when the software improves, will be easily
   re-rendered) )
 (have something for identifying folders, or helping you to label
  and organize them in the first place)
 (have it OCR the documents as it is scanning to detect already
  scanned documents)
 (have it scan all the documents in the ADF at the same time)
 (add a feature where it helps you to count how many pages have
  been scanned, so that if the ADF misses one...)

 (fix has-datetimestamp not being asserted when scanning a new
  item, or specifically when putting "actiondone" on it.  look to
  the fix-timing stuff for how to assert it.)

 (fix the one item I scanned in most recently, add a datetimestamp to it)

 (have it add datetimestamps where necessary)

 (have a completed highlight ready, i.e. a gray25 or gray50 with
  blue or something)

 (fix OCR options and isemptyandshould be deleted esp. for ImagePDF type)
 (Justin says - just put a bunch of stuff in the document feeder
  and have it figure out what is what)

 (have the ability for it to detect, when scanning in a multipage
  document, whether it thinks the doc has already been scanned in,
  and alert the user before they rescan the whole thing.  Of
  course, it could simply be a doc that has the same initial
  pages, so have to verify with the user - show the document it
  has to see if it is the same, then again, could differ only in a
  few words the user might not notice)

 (record the source of documents, such as, Mail, Received in
  person, etc)

 (fill out my applications)

 (scan all my urgent documents)

 (fix the folder headings so that we can access all folders)
 (get rid of the delay time)
 (add auto classificiation so that we can quickly classify documents from incoming to their proper destinations)
 (fix the delete option)
 (fix the conversion from images to pdf)

 (add a find similar feature)


 (setup datetimestamps for import and scan functions)
 (fix the current folder sorting options)
 (add more (working) sorting options eventually)
 (fix the metadata display of folders and
  datetimestamp (datetimestamp should format like Aug 10 2010))
 (clean up the forced removal of trash)
 (complete conversion between multipleimages and pdf formats)
 (add a website format hopefully)
 (see if we can integrate gscan2pdf)
 (add the ability to move between folders)


 (monitor the size of the trash folder and periodically ask to
  clear it, or put in a check to delete it every so often or after
  items are moved there...)

 (partially complete (fix the folders not being stored in metadata))

 (get scrollbars to work)
 (eliminate time to reload everything)

 (partially complete (have ability to edit based on type, also edit for images))
 (partially complete (have the ability to index items that don't have fulltext using OCR))
 (partially complete (have the ability to delete items))

 (partially complete (have the ability to order items according to different sorting orders))

 (fix display bug)

 (partially complete (have a View -> By (Create Date, Modify Date, ?Access Date?, Hrm. (Desc))))

 (have the ability to edit meta data and to rotate between items)


 (completed (add backup feature that exports everything to a tar.gz file or something))

 (have menu options that change based on the type of object, so
  for instance, if an object is classified as a bill, it has an
  option to pay and maybe also an option to mark paid)
 (add the ability to splice apart an image or pdf into smaller
  documents, for when say you scan multiple unrelated items
  together.  Also add the ability to break on pages.)
 (add the ability to move items between folders)
 (add website saving support)
 (add crypto signing and md5sums)
 (add image rotation)
 (have the ability to analyze the text contents, and extract dates)
 (have the ability to flag items with custom tags)
 (have a special page for editing an item, which tells which type of item it is, allows you to convert it to other types, shows you what flags there are, etc.)
 (have the ability to export the database sans the has-fulltext option)
 (have the ability to specify which physical folder a document is in)
 (setup document classification)
 (partially complete (improve the scanning interface))
 )






(http://www.troubleshooters.com/linux/pdf2gimp2pdf.htm)

(each document has a particular folder that you want to put it in - possibly even keep the order of the papers in the folder correct)
(deal with document physically missing (as in cannot be found) in the cabinet)
(deal with document removal and replacement into the cabinet)

(add a manual classification system for documents, which has
 context sensitive menus, for instance, bills have the option to
 drag down and mark as paid)

(add a feature for marking bills/invoices, etc paid, or payment
 received, preferably with some kind of pointer to proof of it)
(add an option for online bill pay - where it recognizes who the
 bill is from etc and sets everything up, just asking for your
 permission
 (also- should learn that $10000 is unusual and have a
  kind of auto-security to prevent ridiculous transactions, etc -
  someone has probably written standards for this.))

(when you load an existing document, it should figure out what
 class it is and load that...)

(all the functions should be called in the right way)
(on loading, it shouldn't recopy things)
(there should be a good persistence mechanism, hopefully file based)

(remove all mentions of Paperport except where absolutely necessary, such as NonFree...)

(clean keyboard)

(have document similarity to ask the user if it is a copy of an
 already scanned document)

(automatic, trainable, priority classification of messages)
(clustering using the bookmarks cluster)
(full text search)
(extraction of dates and reminders based on dates in text)
(search within a cateory)
(prune files based on date/importance to clear space in physical filing cabinets)
(sharable documents)
(automatic classification/declassification/redaction, etc.)
(title,summary,etc. other metadata)
(semantic indexing of concepts using Sayer, etc.)
(processing using various FRDCSA tools, such as Capability::TextAnalysis)

(have automatic orientation for OCR)

(have it be able to print pages that are only stored digitally)
(accept all file types)

(add detection of when OCR fails (either due to color or orientation))

(handle things like double sided documents)

(Have the ability to check in and out documents from the filing cabinet, for instance, if you are scanning something for someone else.)

(ask on hplip site how to check whether something is in the ADK document feeder)

(allow for things like Justin's handwritten notes, that don't have to have text analysis done)

(add approximate searching to account for OCR errors)

(write a little gui)

(make thumbnails of each page)

(System
 (Hardware
  (Scanner)
  (Buckets
   (To Scan
    )
   (To Scan Backup)
   (To be classified into To Scan or To Dispose)
   (To Dispose)
   )
  (Filing Cabinets
   (Top Unit
    (Top Shelf
     )
    (Bottom Shelf)
    )
   (Bottom Unit
    (Top Shelf)
    (Bottom Shelf)
    )
   )
  )
 (Software
  (Paperless-Office software)
  (Paperport)
  )
 (Processes
  )
 )

(    my $scrollframe = $args{Frame}->Scrolled
      (
       'Frame',
       -background => 'white',
       -scrollbars => 'n',
      );
    $self->MyFrame($scrollframe);
    # $args{Frame}->pack(-expand => 1, -fill => 'both');
)
