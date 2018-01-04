@echo off
cls
set rootfolder="PATH\TO\YOUR\CLEANUP\FOLDER"
echo ===============================================================================
echo.
echo Enumerating all MKVs under %rootfolder%
echo.
echo ===============================================================================
echo.
for /r %rootfolder% %%a in (*.mkv) do (
     mkvpropedit "%%a" -d title
     mkvpropedit "%%a" -e track:v1 -d name
     mkvpropedit "%%a" -e track:a1 -d name
     mkvpropedit "%%a" -e track:s1 -d name
     mkvpropedit "%%a" --tags all:
     echo.
     echo ===============================================================================
     echo.
     echo Title cleaning in file "%%a" is done.
     echo.
     echo ===============================================================================
     echo.
     echo Searching for subtiltes in "%%a".
     echo.
     echo ===============================================================================
     echo.
     for /f %%b in ('mkvmerge  --ui-language en -i "%%a" ^| find /c /i "subtitles"') do (
        if [%%b]==[0] (
            echo "%%a" has no subtitles.
	    echo Nothing extracted.
        ) else (
            echo %%a has subtitles.
            set "line="
            for /f "delims=" %%i in ('mkvmerge --ui-language en --identify-verbose "%%a" ^| sed "/subtitles/!d;/language:und/!d;s/.* \([0-9]*\):.*/\1/"') do (
                echo(Undetermined Track ID: %%i
                call set line=%%line%% %%i:"%%~dpna.und.srt"
            )
            setlocal enabledelayedexpansion
            mkvextract tracks "%%a" --ui-language en !line! ||(echo Demuxing error!&goto:eof)
	    sed "3d" "%%~dpna.und.srt" > "%%~dpna.und1.srt"
	    del /f "%%~dpna.und.srt"
	    sed "3d" "%%~dpna.und1.srt" > "%%~dpna.clean.und.srt"
	    del /f "%%~dpna.und1.srt"
            endlocal
        )
        echo.
	echo ===============================================================================
        echo.
    )
    for /f %%b in ('mkvmerge -i "%%a" ^| find /c /i "subtitles"') do (
        if [%%b]==[0] (
            echo "%%a" has no subtitles.
            echo Nothing deleted.
        ) else (
            echo "%%a" has subtitles.
            mkvmerge -q -o "%%~dpna (No Subs)%%~xa" -S "%%a"
            if errorlevel 1 (
                echo Warnings/errors generated during remuxing, original file not deleted.
            ) else (
                del /f "%%a"
                echo Successfully remuxed to "%%~dpna (No Subs)%%~xa", original file deleted.
            )
        )
        echo.
        echo ===============================================================================
        echo.
    )
    for /f %%b in ('mkvmerge -i "%%a" ^| find /c /i "subtitles"') do (
        if [%%b]==[0] (
            echo "%%a" has no subtitles.
            echo Starting remux process.
            echo.
	    mkvmerge -o "%%~dpna (Edited Subs)%%~xa" --default-track 0 --language 0:und "%%~dpna.clean.und.srt" "%%~dpna (No Subs)%%~xa"
            if errorlevel 1 (
                echo Warnings/errors generated during remuxing, original file not deleted.
            ) else (
                del /f "%%~dpna (No Subs)%%~xa"
		del /f "%%~dpna.clean.und.srt"
                echo Successfully remuxed to "%%~dpna (Edited Subs)%%~xa", original file deleted.
            )
        ) else (
            echo "%%a" has subtitles.
            echo Nothing remuxed.
        )
        echo.
	echo ===============================================================================
        echo.
    )
)
