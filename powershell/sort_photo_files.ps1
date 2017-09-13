$whileLoop = 1

#[Console]::OutputEncoding = [System.Text.Encoding]::GetEncoding("cp1251")
$sourcePath = "D:\unsorted_photos"

$logfileFullPath = "$sourcePath\_sort_photos.log"

function Write-OutAndLog {
  $stringToWrite = $args[0]

  $dateTime = (get-date -f "dd-MM-yyyy HH:mm:ss")
  $timestamp = "[$dateTime]"
  $messageText = "$timestamp - $stringToWrite"
  Write-Host "$messageText"
  Out-File -FilePath $logfileFullPath -InputObject $messageText -Append -encoding unicode
}

function Sort-PhotoFiles {
  $funcInitials = "[SRTFLS]"
  $photoRegex = "^\d{4}-\d{2}-\d{2}_\d{2}-\d{2}-\d{2}_\d{5,6}\..*$"
  $arrayPhotoFiles = (Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -match $photoRegex })
  $arrayPhotoFilesNum = 0
  $arrayPhotoFilesNum = ($arrayPhotoFiles.Count)
  if ($arrayPhotoFilesNum -gt 0) {
    Write-OutAndLog "$funcInitials Sorting photos..."
    $arrayPhotoNames = ($arrayPhotoFiles -replace '-\d{2}_\d{2}-\d{2}-\d{2}_\d{5,6}.*', '' -replace '-', '.')
    $arrayPhotoUniqueDate = ($arrayPhotoNames | Sort-Object | Get-Unique)
    ForEach ($photoUniquieDate in $arrayPhotoUniqueDate) {
      if (!(Test-Path $sourcePath\$photoUniquieDate)) {
        Write-OutAndLog "$funcInitials Create folder $sourcePath\$photoUniquieDate\ for photo files"
        New-Item -ItemType directory -Path $sourcePath\$photoUniquieDate
      }
      $photoRegexByDate = "^$photoUniquieDate-\d{2}_\d{2}-\d{2}-\d{2}_\d{5,6}\..*$"
      Write-OutAndLog "$funcInitials Search photos match $photoRegexByDate..."
      $arrayPhotoByDate = (Get-ChildItem -Path $sourcePath | Where-Object { $_.Name -match $photoRegexByDate })
      $arrayPhotoByDateNum = 0
      $arrayPhotoByDateNum = ($arrayPhotoByDate.Count)
      if ($arrayPhotoByDateNum -gt 0) {
        Write-OutAndLog "$funcInitials Move photos by date $photoUniquieDate..."
        ForEach ($photoFile in $arrayPhotoByDate) {
#          Write-OutAndLog "Move photo $photoFile to $sourcePath\$photoUniquieDate\"
          Move-Item -Path $sourcePath\$photoFile -Destination $sourcePath\$photoUniquieDate -Force
        }
        Write-OutAndLog "$funcInitials Done. Moved $arrayPhotoByDateNum photos to $sourcePath\$photoUniquieDate\ ."
      }
    }
    Write-OutAndLog "$funcInitials Done. $arrayPhotoFilesNum photos sorted."
  }
}

Sort-PhotoFiles
