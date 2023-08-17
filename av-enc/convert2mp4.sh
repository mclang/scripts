#!/bin/bash
# Converts given video(s) into AV1 or h265 mp4 files using `ffmpeg`.
#
### How to use `ffmpeg`/`ffprobe`:
# - https://trac.ffmpeg.org/wiki/FFprobeTips
# - https://trac.ffmpeg.org/wiki/Encode/H.265
# - https://trac.ffmpeg.org/wiki/Encode/AV1
# - https://abdus.dev/posts/ffmpeg-metadata/
#
### Using SVT-AV1 within ffmpeg
# - https://gitlab.com/AOMediaCodec/SVT-AV1/-/blob/master/Docs/CommonQuestions.md
# - https://gitlab.com/AOMediaCodec/SVT-AV1/-/blob/master/Docs/Ffmpeg.md
# ==> For personal use, try `-preset 5 -crf 32 -g 240 -pix_fmt yuv420p10le -svtav1-params tune=0:film-grain=8`.
#
### Choosing SVT-AV1 preset and CRF:
# - https://slhck.info/video/2017/02/24/crf-guide.html
# - https://streaminglearningcenter.com/encoding/choosing-a-preset-for-svt-av1-or-any-codec.html
# - https://www.reddit.com/r/AV1/comments/s7yyf9/help_me_understand_svtav1_parameters/
# - https://www.reddit.com/r/AV1/comments/w9lnjz/crf_value_for_efficient_4k_encoding/
#
# https://github.com/xiph/rav1e
#
#
# NOTES:
# - Normally `ffmpeg` outputs into `stderr` so use `2>&1` when logging into file.
# - Force 8/10-bit output using either `-pix_fmt yuv420p` or `-pix_fmt yuv420p10le` respectively but only ID NEEDED.
# - Use VMAF for comparing videos - it tries to replicate what human eye sees.
#
# QUESTIONS:
# - Is something like `format=yuv420p` needed for better compatibility?
#
set -u
set -eo pipefail
shopt -s nullglob
shopt -s nocasematch

# Encoder codec selection and basic options
ENC_LIBRARY="libsvtav1"
# ENC_LIBRARY="rav1e"

# Something like '20'/'4' for AV1 and '25'/'slow' for h265
# Maybe 20 for 4k, 30 for 1080p and 40 for 720p (av1)?
# ENC_OPTS="-crf XXX -preset YYY"

AV1_FILM_GRAIN="8"  # Set e.g 4 for less grainy 2d/3d anime and e.g 10 for noisier live videos

# Usable only when using AV1. Taken from:
# https://s8r8b7.a2cdn1.secureserver.net/wp-content/uploads/2022/07/svt-av1-preset2c.png
PRESET_BRATE_COEF=( # Encoding time compared to 100% (preset 0)
	[3]="1.05"      # 7.66%
	[4]="1.13"      # 3.34% <-- Used with CRF 34 to encode BR rips with acceptable results (https://www.reddit.com/r/AV1/comments/ymrs5v/comment/iv5ub1l/?utm_source=share&utm_medium=web2x&context=3)
	[5]="1.17"      # 1.91% <-- Maybe good for 1080p using CFR 30
	[6]="1.27"      # 0.96%
	[7]="1.30"      # 0.63%
	[8]="1.42"      # 0.41%
)
for PRESET in "${!PRESET_BRATE_COEF[@]}"; do
	echo "$PRESET ==> ${PRESET_BRATE_COEF[$PRESET]}"
done

for CMD in "ffmpeg" "ffprobe" "paste"; do
	command -v "$CMD" >/dev/null && continue
	echo "ERROR: '$CMD' not found!"
	exit
done


# Parameters for `ffprobe`:
#   * `-v error`:         Skip generic build and file information, show errors only.
#   * `-select_streams v`: Select only video streams. Using `v:0` would select the first video stream.
#   * `-show_entries stream=codec_name`: Show only the `codec_name` of the selected stream.
#   * `-of default=nw=1:nk=1`: Use default output format with `noprint_wrappers=1:nokey=1` -> gives ONLY the value.
#
# Parameters for `ffmpeg`:
#   * `-map_metadata 0`:             Copies only KNOWN metadata fields from input into output
#   * `-movflags use_metadata_tags`: Copies ALL metadata fields from input to output. MUST BE AFTER INPUT FILE!
#   * `-c:a copy`:    Copy audio streams WITHOUT re-encoding.
#   * `-c:v libx265`: Encode video stream using x265 library.
#   * `-crf <?>`:     Constant Rate Factor, i.e the QUALITY. Default 28 of h265 corresponds 23 of h264, but results in about half the filesize.
#   * `-preset <?>`:  Compression efficiency and encoding speed. Try `medium` (default) and `slow`, `slower`, `veryslow`.
#   * `-tag:v hvc1`: Needed for Apple "industry standard" H.265 :/
#
function convert_hevc ()
{
	local CRF="25"          # Defaul: 28 should give same quality as 23 gives with h264 but in half the size
	local PRESET="slower"   # Default: medium
	ffmpeg -hide_banner -loglevel error -stats \
		-i "$VIDEO" \
		-movflags use_metadata_tags \
		-metadata comment="Re-encoded on $(date +'%Y') with 'ffmpeg' using crf: $CRF and preset: $PRESET"
		-c:a copy -c:v libx265 -crf $CRF -preset $PRESET -g ??? \
		-tag:v hvc1 \
		"$OUTPUT"
}


for VIDEO in "$@"; do
	echo ""
	echo "### PROCESSING '$VIDEO' ###"
	AUDIO_CODEC="$(ffprobe -v error -select_streams a -show_entries stream=codec_name   -of default=nw=1:nk=1 "$VIDEO")"
	AUDIO_BRATE="$(ffprobe -v error -select_streams a -show_entries stream=bit_rate     -of default=nw=1:nk=1 "$VIDEO")"
	AUDIO_SRATE="$(ffprobe -v error -select_streams a -show_entries stream=sample_rate  -of default=nw=1:nk=1 "$VIDEO")"
	VIDEO_CODEC="$(ffprobe -v error -select_streams v -show_entries stream=codec_name   -of default=nw=1:nk=1 "$VIDEO")"
	VIDEO_BRATE="$(ffprobe -v error -select_streams v -show_entries stream=bit_rate     -of default=nw=1:nk=1 "$VIDEO")"
	VIDEO_FRATE="$(ffprobe -v error -select_streams v -show_entries stream=r_frame_rate -of default=nw=1:nk=1 "$VIDEO")"
	VIDEO_SIZE="$(ffprobe  -v error -select_streams v -show_entries stream=width,height -of default=nw=1:nk=1 "$VIDEO" | paste -sd 'x')"
	CREATED="$(ffprobe  -v error -select_streams v -show_entries stream_tags=creation_time -of default=nw=1:nk=1 "$VIDEO")"
	DURATION="$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$VIDEO")"
	FILESIZE="$(ffprobe -v error -show_entries format=size     -of default=nw=1:nk=1 "$VIDEO")"

	# Rounding e.g '5 * 30000/1001' up to '150' needs some workaround magic in Bash/BC :/
	# NOTE: With STV-AV1 `keyint=5s` could be used directly, but this doen not work with ffmpeg's `-g` (GOP) parameter
	GOP_SIZE="$(echo "kfg=5*${VIDEO_FRATE}; kfg+=0.5; scale=0; kfg/1" | bc -l)"

	echo "- audio:    $AUDIO_CODEC ($AUDIO_SRATE Hz, $(echo "scale=0; $AUDIO_BRATE / 1000" | bc -l) kb/s)"
	echo "- video:    $VIDEO_CODEC ($VIDEO_SIZE, $(echo "scale=2; $VIDEO_FRATE" | bc -l) fps, $(echo "scale=0; $VIDEO_BRATE / 1000" | bc -l) kb/s)"
	echo "- created:  $CREATED"
	echo "- duration: $(date -d "@${DURATION}" -u +'%H:%M:%S')"
	echo "- size:     $(echo "scale=1; $FILESIZE / 1024 / 1024" | bc -l) MiB"

	if [[ "$AUDIO_CODEC" != "aac"  ]]; then
		echo "WARNING: Audio codec '$AUDIO_CODEC' might NOT be optimal for av1/h265 video"
		echo "==> Maybe something like '-c:a aac -b:a <original>' or OPUS should be used?"
	fi
	if [[ "$VIDEO_CODEC" =~ av1|h265|hevc  ]]; then
		echo "WARNING: File is already in '$VIDEO_CODEC' format - little use to re-encode!"
		echo "==> Skipping the file"
		continue
	fi
	OUTPUT="${VIDEO%.*}_${ENC_CODEC}.mp4"
	if [[ -e "$OUTPUT" ]]; then
		echo "WARNING: Destination file already exists!"
		echo "==> Skipping the file"
		continue
	fi
	echo "==> '$OUTPUT' (keyframe interval: $GOP_SIZE)"


	for CRF in 20 23 25 28; do # h265/HEVC (default: 28)
	# for CRF in 20 30 40 50; do # AV1 (default: 50)
		for PRESET in "medium" "slow" "slower"; do
		# for PRESET in "8" "5" "3"; do
			echo ""
			echo "###  $CRF - $PRESET  ###"
			OUTPUT="${VIDEO%.*}_${ENC_CODEC}-${CRF}-${PRESET}.mp4"

			TS_START="$(date +'%s')"
			time ffmpeg -hide_banner -loglevel error -stats \
				-i "$VIDEO" \
				-map_metadata 0 \
				-metadata title="???" \
				-metadata comment="Re-encoded on $(date +'%Y') using 'ffmpeg' '$ENC_LIBRARY' (crf=$CRF, preset=$PRESET, film-grain=$AV1_FILM_GRAIN, tune=0)" \
				-pix_fmt yuv420p10le \
				-c:a copy -c:v $ENC_LIBRARY -crf $CRF -preset $PRESET -svtav1-params "film-grain=$AV1_FILM_GRAIN:keyint=10s:tune=0" \
				"$OUTPUT"
			TS_STOP="$(date +'%s')"

			NEWFSIZE="$(ffprobe -v error -show_entries format=size -of default=nw=1:nk=1 "$OUTPUT")"
			SZRATIO="$(echo "scale=1; 100 * $NEWFSIZE / $FILESIZE" | bc -l)"
			echo "==> Size ratio: ${SZRATIO}% ($FILESIZE -> $NEWFSIZE)"
			echo "==> Time (sec): $(echo "$TS_STOP - $TS_START" | bc)"
			touch -d "${CREATED}" "${OUTPUT}"
			# break
		done
		# break
	done
#	ffmpeg -i "$VIDEO" -c:a copy -c:v libx265 -crf 23 -preset veryslow -tag:v hvc1 "$OUTPUT"
#	ffmpeg -i "$VIDEO" -c:a copy -c:v libx265 -profile:v high -level:v 4.2 -preset medium -crf 23 -tag:v hvc1 "$OUTPUT"

#	NSIZE="$(ffprobe  -v error -select_streams v -show_entries format=size -of default=nw=1:nk=1 "$OUTPUT")"
#	SZRATIO="$(echo '100 * ($NSIZE / $FILESIZE)' | bc -l)"
#	echo "==> Size ratio: ${SZRATIO}% ($FILESIZE -> $NSIZE)"

	# Set timestamp of the output file using either filesystem or metadata timestamp:
	if [[ -z "$CREATED" ]]; then
		echo "WARNING: Source video does not have 'created_time' metadata!"
		echo "==> Using filesystem timestamp instead..."
		touch --no-create -r "${VIDEO}" "${OUTPUT}"
	else
		touch --no-create -d "${CREATED}" "${OUTPUT}"
	fi
done

