@echo off
echo Pulling latest auth.db...
adb exec-out run-as com.example.frontend cat databases/auth.db > "C:\Users\Amir\Desktop\Studygded\Degree Year 3\Semester 2\Mobile Application Development\TaskFlow\frontend\lib\auth.db"

echo Pulling latest tasks.db...
adb exec-out run-as com.example.frontend cat databases/tasks.db > "C:\Users\Amir\Desktop\Studygded\Degree Year 3\Semester 2\Mobile Application Development\TaskFlow\frontend\lib\tasks.db"

echo Done. Files saved to project lib folder.
pause
