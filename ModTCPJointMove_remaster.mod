MODULE ModTCPJointMove
    PERS jointtarget current_jpos:=[[16,12,12,3,30,0],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
    PERS robtarget current_lpos:=[[225.7,217.7,257],[0.653245,-0.27055,0.653328,0.270622],[0,-1,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
    PERS robtarget current_tlpos:=[[225.7,217.7,257],[0.653245,-0.27055,0.653328,0.270622],[0,-1,-1,1],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
    PERS robtarget current_tcppos:=[[431.075,171.505,500.61],[0.2468,0.4967,-0.815,0.16],[0,0,0,0],[9E+9,9E+9,9E+9,9E+9,9E+9,9E+9]];
    PERS tooldata tool1;
    PERS wobjdata wob1;
    VAR string moveType;
    VAR socketdev clientSocket;
    VAR socketdev serverSocket;
    VAR string readStr;
    VAR string sendStr;
    VAR string statusStr := "";
    VAR jointtarget jt_recv;
    VAR robtarget pos_recv;
    VAR robtarget tpos_recv;
    VAR robtarget tcp_recv;
    VAR jointtarget curr_jt;
    VAR robtarget curr_pos;
    VAR robtarget curr_tpos;
    VAR robtarget curr_tcp;
    VAR robjoint robax_curr_jt;
    VAR pos trans_curr_pos;
    VAR pos trans_curr_tpos;
    VAR pos rot_curr_tcp;
    VAR string sendCURR_JT;
    VAR string sendCURR_POS;
    VAR string sendCURR_TPOS;
    VAR string sendCURR_TCP;
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
    VAR string x;
    VAR string y;
    VAR string z;
    VAR num parsedX;
    VAR num parsedY;
    VAR num parsedZ;
    VAR bool checkX;
    VAR bool checkY;
    VAR bool checkZ;
    VAR string t_x;
    VAR string t_y;
    VAR string t_z;
    VAR num parsedT_X;
    VAR num parsedT_Y;
    VAR num parsedT_Z;
    VAR bool checkT_X;
    VAR bool checkT_Y;
    VAR bool checkT_Z;
    VAR string deg_x;
    VAR string deg_y;
    VAR string deg_z;
    VAR num parsedDEG_X;
    VAR num parsedDEG_Y;
    VAR num parsedDEG_Z;
    VAR bool checkDEG_X;
    VAR bool checkDEG_Y;
    VAR bool checkDEG_Z;
    VAR num firstComma;
    VAR num secondComma;
    VAR num thirdComma;
    VAR num fouthComma;
    VAR num fifthComma;
    VAR num anglex;
    VAR num angley;
    VAR num anglez;

    PROC SetJointAndMove()
        IF moveType = "JOINT" THEN
            MoveAbsJ current_jpos, v100, fine, tool1 \WObj:=wob1;
        ELSEIF moveType = "LINEAR" THEN
            MoveJ current_lpos, v100, fine, tool1 \WObj:=wob1;
        ELSEIF moveType = "TOOL LINEAR" THEN
            MoveJ current_tlpos, v100, fine, tool1 \WObj:=wob1;
        ELSEIF moveType = "TCP" THEN
            MoveJ current_tcppos, v100, fine, tool1 \WObj:=wob1;
        ENDIF
    ENDPROC

    PROC Main()
        ! Create and bind a socket on port 5000
        SocketServer;
        TPWrite "Waiting for connection...";
        ! Instead, directly read data when it's available
        SocketAccept clientSocket, serverSocket,\Time:=WAIT_MAX;
        tool1 := Gripper;
        wob1 := w_function1;
        CheckMoveType;
        WHILE TRUE DO 
            IF moveType = "JOINT" THEN
                ReceiveNewJointsAndMove;
                current_jpos := CJointT();
                current_jpos.robax := [parsedJ1,parsedJ2,parsedJ3,parsedJ4,parsedJ5,parsedJ6];
            ELSEIF moveType = "LINEAR" THEN
                ReceiveNewPositionsAndMove;
                current_lpos := CRobT(\Tool:=tool1 \WObj:=wobj0);
                current_lpos.trans := [parsedX,parsedY,parsedZ];
            ELSEIF moveType = "TOOL LINEAR" THEN
                ReceiveNewToolPositionsAndMove;
                current_tlpos := CRobT(\Tool:=tool1 \WObj:=wob1);
                current_tlpos := RelTool(curr_tpos, parsedT_X, parsedT_Y, parsedT_Z);
            ELSEIF moveType = "TCP" THEN
                ReceiveNewQuaternionsAndMove;
                current_tcppos := CRobT(\Tool:=tool1 \WObj:=wob1);
                current_tcppos.rot := current_tcppos.rot * OrientZYX(parsedDEG_Z, parsedDEG_Y, parsedDEG_X);
                TPWrite "DONE";
            ENDIF
            SetJointAndMove;
        ENDWHILE
        SocketSend serverSocket \Str:="Done Moving";
        SocketClose serverSocket;
        SocketClose clientSocket;
    ENDPROC
    
    PROC SendCurrentJoints()
        VAR num absThreshold;
        
        absThreshold := 0.0001;
        ! Convert joint target to string
        sendStr := "";
        curr_jt := CJointT();
        robax_curr_jt := curr_jt.robax;
        
        IF Abs(robax_curr_jt.rax_1) < absThreshold THEN
            robax_curr_jt.rax_1 := 0;
        ENDIF
        IF Abs(robax_curr_jt.rax_2) < absThreshold THEN
            robax_curr_jt.rax_2 := 0;
        ENDIF
        IF Abs(robax_curr_jt.rax_3) < absThreshold THEN
            robax_curr_jt.rax_3 := 0;
        ENDIF
        IF Abs(robax_curr_jt.rax_4) < absThreshold THEN
            robax_curr_jt.rax_4 := 0;
        ENDIF
        IF Abs(robax_curr_jt.rax_5) < absThreshold THEN
            robax_curr_jt.rax_5 := 0;
        ENDIF
        IF Abs(robax_curr_jt.rax_6) < absThreshold THEN
            robax_curr_jt.rax_6 := 0;
        ENDIF
        
        robax_curr_jt := [Round(robax_curr_jt.rax_1\Dec:=2), Round(robax_curr_jt.rax_2\Dec:=2), 
                          Round(robax_curr_jt.rax_3\Dec:=2), Round(robax_curr_jt.rax_4\Dec:=2), 
                          Round(robax_curr_jt.rax_5\Dec:=2), Round(robax_curr_jt.rax_6\Dec:=2)];
                                    
        current_jpos.robax := robax_curr_jt;
        sendCURR_JT := ValToStr(robax_curr_jt);
        TPWrite "Value sendStr: "+ sendCURR_JT;
        ! sendCURR_JT := StrPart(sendCURR_JT, 1, StrLen(sendCURR_JT)-1);
        SocketSend serverSocket \Str := sendCURR_JT;
    ENDPROC
    
    PROC SendCurrentPositions()
        VAR num absThreshold;
        
        absThreshold := 0.0001;
        ! Convert joint target to string
        sendStr := "";
        curr_pos := CRobT(\Tool:=tool1 \WObj:=wob1);
        trans_curr_pos := curr_pos.trans;
        
        IF Abs(trans_curr_pos.x) < absThreshold THEN
            trans_curr_pos.x := 0;
        ENDIF
        IF Abs(trans_curr_pos.y) < absThreshold THEN
            trans_curr_pos.y := 0;
        ENDIF
        IF Abs(trans_curr_pos.z) < absThreshold THEN
            trans_curr_pos.z := 0;
        ENDIF
        
        trans_curr_pos := [Round(trans_curr_pos.x\Dec:=4), Round(trans_curr_pos.y\Dec:=4), 
                          Round(trans_curr_pos.z\Dec:=4)];
                          
        current_lpos.trans := trans_curr_pos;
        sendCURR_POS := ValToStr(trans_curr_pos);
        TPWrite "Value sendStr: "+ sendCURR_POS;
        ! sendCURR_JT := StrPart(sendCURR_JT, 1, StrLen(sendCURR_JT)-1);
        SocketSend serverSocket \Str := sendCURR_POS;
    ENDPROC
    
    PROC SendCurrentToolPositions()
        VAR num absThreshold;
        
        absThreshold := 0.0001;
        ! Convert joint target to string
        sendStr := "";
        curr_tpos := CRobT(\Tool:=tool1 \WObj:=wob1);
        trans_curr_tpos := curr_tpos.trans;
        
        IF Abs(trans_curr_tpos.x) < absThreshold THEN
            trans_curr_tpos.x := 0;
        ENDIF
        IF Abs(trans_curr_tpos.y) < absThreshold THEN
            trans_curr_tpos.y := 0;
        ENDIF
        IF Abs(trans_curr_tpos.z) < absThreshold THEN
            trans_curr_tpos.z := 0;
        ENDIF
        
        trans_curr_tpos := [Round(trans_curr_tpos.x\Dec:=4), Round(trans_curr_tpos.y\Dec:=4), 
                          Round(trans_curr_tpos.z\Dec:=4)];
                          
        current_tlpos.trans := trans_curr_tpos;
        sendCURR_TPOS := ValToStr(trans_curr_tpos);
        TPWrite "Value sendStr: "+ sendCURR_TPOS;
        ! sendCURR_JT := StrPart(sendCURR_JT, 1, StrLen(sendCURR_JT)-1);
        SocketSend serverSocket \Str := sendCURR_TPOS;
    ENDPROC
    
    PROC SendCurrentQuaternions()
        VAR num absThreshold;
        
        absThreshold := 0.0001;
        ! Convert joint target to string
        sendStr := "";
        curr_tcp := CRobT(\Tool:=tool1 \WObj:=wob1);
        convert_toZYX;
        
        IF Abs(anglex) < absThreshold THEN
            anglex := 0;
        ENDIF
        IF Abs(angley) < absThreshold THEN
            angley := 0;
        ENDIF
        IF Abs(anglez) < absThreshold THEN
            anglez := 0;
        ENDIF
        
        rot_curr_tcp := [Round(anglex\Dec:=4), Round(angley\Dec:=4), 
                          Round(anglez\Dec:=4)];

        sendCURR_TCP := ValToStr(rot_curr_tcp);
        TPWrite "Value sendStr: "+ sendCURR_TCP;
        ! sendCURR_JT := StrPart(sendCURR_JT, 1, StrLen(sendCURR_JT)-1);
        SocketSend serverSocket \Str := sendCURR_TCP;
    ENDPROC
    
    PROC convert_toZYX()
        anglex:=EulerZYX(\X,curr_tcp.rot);
        angley:=EulerZYX(\Y,curr_tcp.rot);
        anglez:=EulerZYX(\Z,curr_tcp.rot);
    ENDPROC
    
    PROC ReceiveNewJointsAndMove()
        TPWrite "Waiting for coming data...";
        SocketReceive serverSocket \Str := readStr;
        IF readStr = "JOINT" OR readStr = "LINEAR" OR readStr = "TOOL LINEAR" OR readStr = "TCP" THEN
            moveType := readStr;
            SocketSend serverSocket \Str := "MOVE TO CHECKING";
            SocketReceive serverSocket \Str := statusStr;
            CheckMoveType;
        ELSE
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
        ENDIF
    ENDPROC
    
    PROC ReceiveNewPositionsAndMove()
        TPWrite "Waiting for coming data...";
        SocketReceive serverSocket \Str := readStr;
        IF readStr = "JOINT" OR readStr = "LINEAR" OR readStr = "TOOL LINEAR" OR readStr = "TCP" THEN
            moveType := readStr;
            SocketSend serverSocket \Str := "MOVE TO CHECKING";
            SocketReceive serverSocket \Str := statusStr;
            CheckMoveType;
        ELSE
            ! Parse CSV: "10,0,0,0,0,0"
            firstComma := StrFind(readStr, 1, ",");
            secondComma := StrFind(readStr, firstComma + 1, ",");
            x := StrPart(readStr, 1, firstComma - 1);
            y := StrPart(readStr, firstComma + 1, secondComma - firstComma - 1);
            z := StrPart(readStr, secondComma + 1, StrLen(readStr) - secondComma - 1);
    	    TPWrite "Value X: "+ x;
            TPWrite "Value Y: "+ y;
            TPWrite "Value Z: "+ z;
            checkX := StrToVal(x, parsedX);
            checkY := StrToVal(y, parsedY);
            checkZ := StrToVal(z, parsedZ);
        ENDIF
    ENDPROC
    
    PROC ReceiveNewToolPositionsAndMove()
        TPWrite "Waiting for coming data...";
        SocketReceive serverSocket \Str := readStr;
        IF readStr = "JOINT" OR readStr = "LINEAR" OR readStr = "TOOL LINEAR" OR readStr = "TCP" THEN
            moveType := readStr;
            SocketSend serverSocket \Str := "MOVE TO CHECKING";
            SocketReceive serverSocket \Str := statusStr;
            CheckMoveType;
        ELSE
            ! Parse CSV: "10,0,0,0,0,0"
            firstComma := StrFind(readStr, 1, ",");
            secondComma := StrFind(readStr, firstComma + 1, ",");
            t_x := StrPart(readStr, 1, firstComma - 1);
            t_y := StrPart(readStr, firstComma + 1, secondComma - firstComma - 1);
            t_z := StrPart(readStr, secondComma + 1, StrLen(readStr) - secondComma - 1);
    	    TPWrite "Value X: "+ t_x;
            TPWrite "Value Y: "+ t_y;
            TPWrite "Value Z: "+ t_z;
            checkT_X := StrToVal(t_x, parsedT_X);
            checkT_Y := StrToVal(t_y, parsedT_Y);
            checkT_Z := StrToVal(t_z, parsedT_Z);
        ENDIF
    ENDPROC
    
    PROC ReceiveNewQuaternionsAndMove()
        TPWrite "Waiting for coming data...";
        SocketReceive serverSocket \Str := readStr;
        IF readStr = "JOINT" OR readStr = "LINEAR" OR readStr = "TOOL LINEAR" OR readStr = "TCP" THEN
            moveType := readStr;
            SocketSend serverSocket \Str := "MOVE TO CHECKING";
            SocketReceive serverSocket \Str := statusStr;
            CheckMoveType;
        ELSE
            ! Parse CSV: "10,0,0,0,0,0"
            firstComma := StrFind(readStr, 1, ",");
            secondComma := StrFind(readStr, firstComma + 1, ",");
            deg_x := StrPart(readStr, 1, firstComma - 1);
            deg_y := StrPart(readStr, firstComma + 1, secondComma - firstComma - 1);
            deg_z := StrPart(readStr, secondComma + 1, StrLen(readStr) - secondComma - 1);
    	    TPWrite "Offset X deg: "+ deg_x;
            TPWrite "Offset Y deg: "+ deg_y;
            TPWrite "Offset Z deg: "+ deg_z;
            checkDEG_X := StrToVal(deg_x, parsedDEG_X);
            checkDEG_Y := StrToVal(deg_y, parsedDEG_Y);
            checkDEG_Z := StrToVal(deg_z, parsedDEG_Z);
        ENDIF
    ENDPROC

    PROC SocketServer()
	! Create and bind a socket on port 5000
        SocketCreate clientSocket;
        SocketBind clientSocket, "127.0.0.1", 6000;  
        SocketListen clientSocket;  ! Wait for incoming connections
    ENDPROC
    
    PROC CheckMoveType()
        IF statusStr <> "GOT MESSAGE" THEN
            TPWrite "Waiting for coming data...";
            SocketReceive serverSocket \Str := moveType;
        ENDIF
        TPWrite "Moving Type: "+ moveType;
    
        SocketSend serverSocket \Str := "DONE CHECKING";
    
        IF moveType = "JOINT" THEN
            SendCurrentJoints;
            IF statusStr = "GOT MESSAGE" THEN
                ReceiveNewJointsAndMove;
                current_jpos := CJointT();
            ENDIF
        ELSEIF moveType = "LINEAR" THEN
            SendCurrentPositions;
            IF statusStr = "GOT MESSAGE" THEN
                ReceiveNewPositionsAndMove;
                current_lpos := CRobT(\Tool:=tool1 \WObj:=wob1);
            ENDIF
        ELSEIF moveType = "TOOL LINEAR" THEN
            SendCurrentToolPositions;
            IF statusStr = "GOT MESSAGE" THEN
                ReceiveNewToolPositionsAndMove;
                current_tlpos := CRobT(\Tool:=tool1 \WObj:=wob1);
            ENDIF
        ELSEIF moveType = "TCP" THEN
            SendCurrentQuaternions;
            IF statusStr = "GOT MESSAGE" THEN
                ReceiveNewQuaternionsAndMove;
                current_tcppos := CRobT(\Tool:=tool1 \WObj:=wob1);
            ENDIF
        ENDIF
        
    ENDPROC
    
ENDMODULE