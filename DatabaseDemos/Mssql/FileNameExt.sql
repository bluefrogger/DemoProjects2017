
B1:        =LEFT(A1,FIND(CHAR(1),SUBSTITUTE(A1,".",CHAR(1),LEN(A1)-LEN(SUBSTITUTE(A1,".",""))))-1)

C1:        =TRIM(RIGHT(SUBSTITUTE(A1,".",REPT(" ",99)),99))

To extract the file name:
=RIGHT(A1,LEN(A1)-FIND("~",SUBSTITUTE(A1,"\","~",LEN(A1)-LEN(SUBSTITUTE(A1,"\","")))))

To extract the file path:
=MID(A1,1,LEN(A1)-LEN(MID(A1,FIND(CHAR(1),SUBSTITUTE(A1,"\",CHAR(1),LEN(A1)-LEN(SUBSTITUTE(A1,"\",""))))+1,LEN(A1))))


Using Java:

String myPath="C:\folder\folder\folder\file.txt";
System.out.println("filename " +  myPath.lastIndexOf('\\'));

