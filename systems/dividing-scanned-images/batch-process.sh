#!/bin/sh

gimp -i -b '(script_fu_BatchDivideScannedImages "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/in" 0 20 1500 5 0 100 100 "/tmp" 0 "cropped" 0)' -b '(gimp-quit 0)'

# (script_fu_DivideScannedImages image drawable inThreshold inSize inLimit inCorner inX inY TRUE inDestDir inSaveType inFileName varCounter)
# gimp --verbose -i -b '(let* ((image (car (gimp-file-load RUN-NONINTERACTIVE "scan1.jpg" "scan1.jpg"))) (drawable (car (gimp-image-get-active-layer image)))) (script_fu_DivideScannedImages image drawable 10 1500 5 0 100 100 "TRUE" "/tmp"  0 "IMAGE" 0) (gimp-image-delete image)) ' -b '(gimp-quit 0)'
# gimp --verbose -i -b '(script_fu_BatchDivideScannedImages "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/in" 0 10 1500 5 0 100 100 "" 0 "IMAGE" 0)' -b '(gimp-quit 0)'

#gimp -i -b '(script_fu_BatchDivideScannedImages "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/in" "jpg" 20 1500 5 "Top Left" 0 0 "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/out" "jpg" "IMAGE" 1)' -b '(gimp-quit 0)'

# gimp -i -b '(script_fu_BatchDivideScannedImages "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/in" 0 20 1500 5 0 100 100 "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/out" 0 "cropped" 1)' -b '(gimp-quit 0)'
# gimp -b '(script_fu_BatchDivideScannedImages "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/in" 0 20 1500 5 0 100 100 "/var/lib/myfrdcsa/codebases/minor/paperless-office/dividing-scanned-images/divide/out" 0 "cropped" 1)' -b '(gimp-quit 0)'