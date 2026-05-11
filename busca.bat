for /R "%USERPROFILE%\.m2\repository\p2\osgi\bundle" %%F in (*.jar) do (
    jar tf "%%F" 2>nul | findstr /I "\.rct$" && echo ^>^>^> Found in: %%F
)