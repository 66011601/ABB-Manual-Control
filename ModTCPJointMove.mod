MODULE ModTCPJointMove
    PERS jointtarget current_jpos:=[[0,0,0,0,0,0],[9E9,9E9,9E9,9E9,9E9,9E9]];
    VAR socketdev clientSocket;
    VAR socketdev serverSocket;
    VAR string readStr;
    VAR string sendStr;
    VAR jointtarget jt;
    VAR jointtarget jt_recv;
    VAR jointtarget curr_jt;
    VAR robjoint robax_curr_jt;
    VAR string sendCURR_JT;
    VAR num parsedCURR_JT;
    VAR num parsedCURR_JT2;
    VAR num parsedCURR_JT3;
    VAR num parsedCURR_JT4;
    VAR num parsedCURR_JT5;
    VAR num parsedCURR_JT6;
    VAR string j1;
    VAR string j2;
    VAR string j3;
    VAR string j4;
    VAR string j5;
    VAR string j6;
    VAR num parsedJ1;
    VAR num parsedJ2;
    VAR num parsedJ3;
    VAR num parsedJ4;
    VAR num parsedJ5;
    VAR num parsedJ6;
    VAR bool checkJ1;
    VAR bool checkJ2;
    VAR bool checkJ3;
    VAR bool checkJ4;
    VAR bool checkJ5;
    VAR bool checkJ6;
    VAR num firstComma;
    VAR num secondComma;
    VAR num thirdComma;
    VAR num fouthComma;
    VAR num fifthComma;

    PROC SetJointAndMove()
        MoveAbsJ current_jpos, v100, fine, tool0;
    ENDPROC

    PROC Main()
        ! Create and bind a socket on port 5000
        SocketServer;
        TPWrite "Waiting for connection...";
        ! Instead, directly read data when it's available
        SocketAccept clientSocket, serverSocket,\Time:=WAIT_MAX;
        SendCurrentJoints;
        WHILE TRUE DO 
            ReceiveNewJointsAndMove;
            current_jpos.robax := [parsedJ1,parsedJ2,parsedJ3,parsedJ4,parsedJ5,parsedJ6];
            SetJointAndMove;
        ENDWHILE
        SocketSend serverSocket \Str:="Done Moving";
        SocketClose serverSocket;
        SocketClose clientSocket;
    ENDPROC
    
    PROC SendCurrentJoints()
        ! Convert joint target to string
        sendStr := "";
        curr_jt := CJointT();
        robax_curr_jt := curr_jt.robax;
        sendCURR_JT := ValToStr(robax_curr_jt);
        TPWrite "Value sendStr: "+ sendCURR_JT;
        ! sendCURR_JT := StrPart(sendCURR_JT, 1, StrLen(sendCURR_JT)-1);
        SocketSend serverSocket \Str := sendCURR_JT;
    ENDPROC
    
    PROC ReceiveNewJointsAndMove()
        TPWrite "Waiting for coming data...";
        SocketReceive serverSocket \Str := readStr;
        ! Parse CSV: "10,0,0,0,0,0"
        firstComma := StrFind(readStr, 1, ",");
        secondComma := StrFind(readStr, firstComma + 1, ",");
        thirdComma := StrFind(readStr, secondComma + 1, ",");
        fouthComma := StrFind(readStr, thirdComma + 1, ",");
        fifthComma := StrFind(readStr, fouthComma + 1, ",");
        j1 := StrPart(readStr, 1, firstComma - 1);
        j2 := StrPart(readStr, firstComma + 1, secondComma - firstComma - 1);
        j3 := StrPart(readStr, secondComma + 1, thirdComma - secondComma - 1);
        j4 := StrPart(readStr, thirdComma + 1, fouthComma - thirdComma - 1);
        j5 := StrPart(readStr, fouthComma + 1, fifthComma - fouthComma - 1);
        j6 := StrPart(readStr, fifthComma + 1, StrLen(readStr) - fifthComma - 1);
	    TPWrite "Value j1: "+ j1;
        TPWrite "Value j2: "+ j2;
        TPWrite "Value j3: "+ j3;
        TPWrite "Value j4: "+ j4;
        TPWrite "Value j5: "+ j5;
        TPWrite "Value j6: "+ j6;
        checkJ1 := StrToVal(j1, parsedJ1);
        checkJ2 := StrToVal(j2, parsedJ2);
        checkJ3 := StrToVal(j3, parsedJ3);
        checkJ4 := StrToVal(j4, parsedJ4);
        checkJ5 := StrToVal(j5, parsedJ5);
        checkJ6 := StrToVal(j6, parsedJ6);
    ENDPROC
    
    PROC SocketServer()
	! Create and bind a socket on port 5000
        SocketCreate clientSocket;
        SocketBind clientSocket, "127.0.0.1", 6000;  
        SocketListen clientSocket;  ! Wait for incoming connections
    ENDPROC
    
ENDMODULE
