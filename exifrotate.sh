#!/bin/bash

exiftool -overwrite_original -if '$ImageWidth > $ImageHeight' -Rotation=270 -ext MP4 -ext mp4 -ext MOV -ext mov .
