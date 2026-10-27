# WINDOWS

- install ffmpeg

## recursivebatchrotate.bat

jalankan pada folder utama yang memiliki sub sub folder yang berisi file video

```
Video/
├── recursivebatchrotate.bat
├── Folder_A/
│   ├── video1.mp4
│   ├── video2.mp4
│   └── output/
│       ├── video1_.MP4
│       └── video2_.MP4
├── Folder_B/
│   ├── video3.MP4
│   ├── video4.mp4
│   └── output/
│       ├── video3_.MP4
│       └── video4_.MP4
└── Folder_C/
    ├── video5.mp4
    └── output/
        └── video5_.MP4
```

tinggal klik 2 kali dan script akan berjalan otomatis.

# Linux

tempatkan script ini di `~/.local/bin/`, 
lalu pastikan folder bin ada di path, 
jika tidak ada, tempatkan ini di .bashrc `export PATH="$HOME/.local/bin:$PATH"`

lalu pastikan tiap script executable `chmod +x batchrotate.sh`

## rotateme.sh, cutonly.sh, cutandrotate.sh

ini single file rotated only

```
rotateme.sh ./video.mp4

cutonly.sh ./video.mp4

cutandrotate.sh ./video.mp4
```

## batchrotate.sh

single folder rotate tanpa recursive

```
Video/
├── batchrotate.sh
└── Folder/
    ├── video1.mp4
    └── output/
        └── video1_.MP4
```

## recursivebatch.sh

jalankan pada folder utama yang memiliki sub sub folder yang berisi file video

```
Video/
├── recursiverotate.sh
├── Folder_A/
│   ├── video1.mp4
│   ├── video2.mp4
│   └── output/
│       ├── video1_.MP4
│       └── video2_.MP4
├── Folder_B/
│   ├── video3.MP4
│   ├── video4.mp4
│   └── output/
│       ├── video3_.MP4
│       └── video4_.MP4
└── Folder_C/
    ├── video5.mp4
    └── output/
        └── video5_.MP4
```
