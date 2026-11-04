GOOGLE DRIVE ICONS REMOVER

FILES
- GoogleDrive_Remove_All_Flags.bat (coordinator script for flag removal)
- GoogleDrive_Restore_All_Flags.bat (coordinator script for restoring flags from backups)
- Hide_Flags_GoogleDrive.bat (script for removal/restoration)

INSTRUCTIONS
Extract all BAT files into the same folder

REMOVING ICON OVERLAYS
- Configure ROOT1, BACKUP1, ROOT2, and BACKUP2 in GoogleDrive_Remove_All_Flags.bat (Pre-filled values are those normally used by Google Drive)
   OR PASS FOUR PATHS TO THE COORDINATOR 
   GoogleDrive_Remove_All_Flags.bat "ROOT1" "BACKUP1" "ROOT2" "BACKUP2" 
- Run GoogleDrive_Remove_All_Flags.bat as administrator.
- GoogleDrive_Remove_All_Flags.bat invokes Hide_Flags_GoogleDrive.bat twice with /norestart
- When /norestart is active, Hide_Flags_GoogleDrive.bat does NOT restart Explorer;
  it returns an exit code: 0 = no changes, 1 = error without
  changes, 2 = one or more changes, 3 = changes and one or more errors
- GoogleDrive_Remove_All_Flags.bat collects the two codes, then restarts Explorer only once
  if at least one code is 2 or 3. If both calls return 0 or 1, it does not restart.
- The reg delete /ve command deletes the default VALUE of the key,
  it does not delete the key itself.

RESTORING ICON OVERLAYS
- Configure ROOT1, BACKUP1, ROOT2, and BACKUP2 in GoogleDrive_Restore_All_Flags.bat (Pre-filled values are those normally used by Google Drive)
   OR PASS FOUR PATHS TO THE COORDINATOR 
   GoogleDrive_Restore_All_Flags.bat "ROOT1" "BACKUP1" "ROOT2" "BACKUP2" 
- Run GoogleDrive_Restore_All_Flags.bat as administrator
- GoogleDrive_Restore_All_Flags.bat invokes Hide_Flags_GoogleDrive.bat twice with "restore" and /norestart
- When /norestart is active, Hide_Flags_GoogleDrive.bat does NOT restart Explorer
- GoogleDrive_Restore_All_Flags.bat collects the exit codes, and if at least one value has been restored, restarts Explorer only once

PRECAUTIONS
- The filter remains GoogleDrive.*OverlayIconHandler$: handlers with different names
  might exist and therefore not be detected.
- Do not use paths containing exclamation marks (!)
- Overlay deletion does not disable the sync engine.
- Forcing an Explorer restart closes open File Explorer windows.
