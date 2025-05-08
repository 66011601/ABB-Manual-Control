import socket
import ast
import time
import keyboard
import os
from scipy.spatial.transform import Rotation as R

# Define ABB robot's virtual controller address
HOST = "127.0.0.1"  # Localhost (RobotStudio)
PORT = 6000         # Port matching RAPID code
INCREMENT = 1.0
SLEEP = 0.1  # Seconds

import numpy as np
from scipy.spatial.transform import Rotation as R

def get_current_joints(client_socket):
    data = client_socket.recv(1024).decode()
    joints = ast.literal_eval(data)
    return joints

def get_current_positions(client_socket):
    data = client_socket.recv(1024).decode()
    pos = ast.literal_eval(data)
    return pos

def get_current_tool_positions(client_socket):
    data = client_socket.recv(1024).decode()
    tpos = ast.literal_eval(data)
    return tpos

def get_current_quaternions(client_socket):
    data = client_socket.recv(1024).decode()
    angle_tcp = ast.literal_eval(data)
    return angle_tcp

def get_respond(client_socket):
    respond = client_socket.recv(1024).decode()
    return respond

def send_new_joints(joints, client_socket):
    joints = [float(f"{a:.4g}") if abs(a) > 0.0001 else 0 for a in joints]
    message = ",".join(str(j) for j in joints)
    client_socket.sendall(message.encode())
    print(f"Sent updated joint targets: {message}")

def send_new_positions(pos, client_socket):
    pos = [float(f"{a:.4g}") if abs(a) > 0.0001 else 0 for a in pos]
    message = ",".join(str(p) for p in pos)
    client_socket.sendall(message.encode())
    print(f"Sent updated positions: {message}")

def send_new_tool_positions(tpos, client_socket):
    tpos = [float(f"{a:.4g}") if abs(a) > 0.0001 else 0 for a in tpos]
    message = ",".join(str(tp) for tp in tpos)
    client_socket.sendall(message.encode())
    print(f"Sent updated tool positions: {message}")

def send_new_quaternions(offset_tcp, client_socket):
    offset_tcp = [float(f"{a:.4g}") if abs(a) > 0.0001 else 0 for a in offset_tcp]
    message = ",".join(str(q) for q in offset_tcp)
    client_socket.sendall(message.encode())
    print(f"Sent updated quaternions: {message}")

def send_moveType(moveType, client_socket):
    message = str(moveType)
    client_socket.sendall(message.encode())
    print(f"Sent moving type: {message}")
    respond = get_respond(client_socket)
    if respond == "MOVE TO CHECKING" :
        message = "GOT MESSAGE"
        client_socket.sendall(message.encode())
        respond = get_respond(client_socket)

def clear_terminal():
    os.system('cls' if os.name == 'nt' else 'clear')

def display_joints(joints):
    clear_terminal()
    print("Move Joints\n")
    for i, val in enumerate(joints):
        print(f"Joint {i+1} : {val:.2f}")
    print("\n[Hold keys 1-6 to move joints, press Q to quit]")
    print("\n[Press keys + to add, press - to minus, press s to send, press l to change to linear mode]")

def display_positions(pos):
    clear_terminal()
    index = ["X", "Y", "Z"]
    print("Move Linear\n")
    for i, val in enumerate(pos):
        print(f"Position {index[i]} : {val:.2f}")
    print("\n[Hold keys 1-3 to move XYZ, press Q to quit]")
    print("\n[Press keys + to add, press - to minus, press s to send, press j to change to joint mode]")

def display_tool_positions(tpos):
    clear_terminal()
    index = ["X", "Y", "Z"]
    print("Move Linear\n")
    for i, val in enumerate(tpos):
        print(f"Offset {index[i]} : {val:.2f}")
    print("\n[Hold keys 1-3 to move XYZ, press Q to quit]")
    print("\n[Press keys + to add, press - to minus, press s to send, press j to change to joint mode]")

def display_quaternions(tcp):
    clear_terminal()
    index = ["X", "Y", "Z"]
    print("Move TCP\n")
    for i, val in enumerate(tcp):
        print(f"Quaternion {index[i]} : {val:.2f}")
    print("\n[Hold keys 1-3 to move angle along X Y Z, press Q to quit]")
    print("\n[Press keys + to add, press - to minus, press s to send, press j to change to joint mode]")

if __name__ == "__main__":

    # Create a socket once and connect
    client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    try:
        client_socket.connect((HOST, PORT))
        print(f"Connected to {HOST}:{PORT}")
    except Exception as e:
        print(f"Connection failed: {e}")
        exit()

    try:
        moving_type = ["JOINT", "LINEAR", "TOOL LINEAR", "TCP"]
        moving_option = int(input("What kind of moving type you like (1 : Joint, 2 : Linear, 3 : Tool Linear, 4 : TCP) : ")) - 1
        send_moveType(moving_type[moving_option], client_socket)
        while True:
            if moving_type[moving_option] == "JOINT" : current_joints = get_current_joints(client_socket)
            elif moving_type[moving_option] == "LINEAR" : current_positions = get_current_positions(client_socket)
            elif moving_type[moving_option] == "TOOL LINEAR" : 
                current_tool_positions = get_current_tool_positions(client_socket)
                offset_tool_positions = [0 for i in range(0, len(current_tool_positions))]
            elif moving_type[moving_option] == "TCP" : 
                current_quaternions = get_current_quaternions(client_socket) # angle along X Y Z
                offset_quaternions = [0 for i in range(0, len(current_quaternions))]
            else : continue
            sign = 1
            while True:
                if moving_type[moving_option] == "JOINT" :
                    display_joints(current_joints)

                    if keyboard.is_pressed('q'):
                        print("Quitting...")
                        break

                    if keyboard.is_pressed('+'):
                        sign = 1
                    elif keyboard.is_pressed('-'):
                        sign = 0

                    moved = False
                    for i in range(6):
                        key = str(i + 1)
                        if keyboard.is_pressed(key) and sign == 1:
                            current_joints[i] += INCREMENT
                            moved = True
                            break  # Move only one joint per cycle
                        elif keyboard.is_pressed(key) and sign == 0:
                            current_joints[i] -= INCREMENT
                            moved = True
                            break  # Move only one joint per cycle

                    if not moved:
                        time.sleep(SLEEP)

                    if keyboard.is_pressed('s'):
                        send_new_joints(current_joints, client_socket)

                    if keyboard.is_pressed('l'):
                        moving_option = 1
                        send_moveType(moving_type[moving_option], client_socket)
                        current_positions = get_current_positions(client_socket)
                    
                    if keyboard.is_pressed('w'):
                        moving_option = 2
                        send_moveType(moving_type[moving_option], client_socket)
                        current_tool_positions = get_current_tool_positions(client_socket)
                        offset_tool_positions = [0 for i in range(0, len(current_tool_positions))]

                    if keyboard.is_pressed('t'):
                        moving_option = 3
                        send_moveType(moving_type[moving_option], client_socket)
                        current_quaternions = get_current_quaternions(client_socket)
                        offset_quaternions = [0 for i in range(0, len(current_quaternions))]

                elif moving_type[moving_option] == "LINEAR" :
                    display_positions(current_positions)

                    if keyboard.is_pressed('q'):
                        print("Quitting...")
                        break

                    if keyboard.is_pressed('+'):
                        sign = 1
                    elif keyboard.is_pressed('-'):
                        sign = 0

                    moved = False
                    for i in range(3):
                        key = str(i + 1)
                        if keyboard.is_pressed(key) and sign == 1:
                            current_positions[i] += INCREMENT
                            moved = True
                            break  # Move only one joint per cycle
                        elif keyboard.is_pressed(key) and sign == 0:
                            current_positions[i] -= INCREMENT
                            moved = True
                            break  # Move only one joint per cycle

                    if not moved:
                        time.sleep(SLEEP)

                    if keyboard.is_pressed('s'):
                        send_new_positions(current_positions, client_socket)
                    
                    if keyboard.is_pressed('j'):
                        moving_option = 0
                        send_moveType(moving_type[moving_option], client_socket)
                        current_joints = get_current_joints(client_socket)

                    if keyboard.is_pressed('w'):
                        moving_option = 2
                        send_moveType(moving_type[moving_option], client_socket)
                        current_tool_positions = get_current_tool_positions(client_socket)
                        offset_tool_positions = [0 for i in range(0, len(current_tool_positions))]
                    
                    if keyboard.is_pressed('t'):
                        moving_option = 3
                        send_moveType(moving_type[moving_option], client_socket)
                        current_quaternions = get_current_quaternions(client_socket)
                        offset_quaternions = [0 for i in range(0, len(current_quaternions))]
                
                elif moving_type[moving_option] == "TOOL LINEAR" :
                    display_tool_positions(offset_tool_positions)

                    if keyboard.is_pressed('q'):
                        print("Quitting...")
                        break

                    if keyboard.is_pressed('+'):
                        sign = 1
                    elif keyboard.is_pressed('-'):
                        sign = 0

                    moved = False
                    for i in range(3):
                        key = str(i + 1)
                        if keyboard.is_pressed(key) and sign == 1:
                            offset_tool_positions[i] += INCREMENT
                            moved = True
                            break  # Move only one joint per cycle
                        elif keyboard.is_pressed(key) and sign == 0:
                            offset_tool_positions[i] -= INCREMENT
                            moved = True
                            break  # Move only one joint per cycle

                    if not moved:
                        time.sleep(SLEEP)

                    if keyboard.is_pressed('s'):
                        send_new_positions(offset_tool_positions, client_socket)
                    
                    if keyboard.is_pressed('j'):
                        moving_option = 0
                        send_moveType(moving_type[moving_option], client_socket)
                        current_joints = get_current_joints(client_socket)

                    if keyboard.is_pressed('l'):
                        moving_option = 1
                        send_moveType(moving_type[moving_option], client_socket)
                        current_positions = get_current_positions(client_socket)
                    
                    if keyboard.is_pressed('t'):
                        moving_option = 3
                        send_moveType(moving_type[moving_option], client_socket)
                        current_quaternions = get_current_quaternions(client_socket)
                        offset_quaternions = [0 for i in range(0, len(current_quaternions))]

                elif moving_type[moving_option] == "TCP" :
                    display_quaternions(offset_quaternions)

                    if keyboard.is_pressed('q'):
                        print("Quitting...")
                        break

                    if keyboard.is_pressed('+'):
                        sign = 1
                    elif keyboard.is_pressed('-'):
                        sign = 0

                    moved = False
                    for i in range(3):
                        key = str(i + 1)
                        if keyboard.is_pressed(key) and sign == 1:
                            offset_quaternions[i] += INCREMENT
                            moved = True
                            break  # Move only one joint per cycle
                        elif keyboard.is_pressed(key) and sign == 0:
                            offset_quaternions[i] -= INCREMENT
                            moved = True
                            break  # Move only one joint per cycle

                    if not moved:
                        time.sleep(SLEEP)

                    if keyboard.is_pressed('s'):
                        send_new_quaternions(offset_quaternions, client_socket)
                    
                    if keyboard.is_pressed('j'):
                        moving_option = 0
                        send_moveType(moving_type[moving_option], client_socket)
                        current_joints = get_current_joints(client_socket)

                    if keyboard.is_pressed('l'):
                        moving_option = 1
                        send_moveType(moving_type[moving_option], client_socket)
                        current_positions = get_current_positions(client_socket)

                    if keyboard.is_pressed('w'):
                        moving_option = 2
                        send_moveType(moving_type[moving_option], client_socket)
                        current_tool_positions = get_current_tool_positions(client_socket)
                        new_tool_positions = current_tool_positions

    except KeyboardInterrupt:
        print("Stopped.")

    except Exception as e:
        print(f"Error: {e}")

    # while True:
    #     # Get user input
    #     try:
    #         current_joints = get_current_joints(client_socket)
    #         print("Current Joint Values:")
    #         for i, j in enumerate(current_joints):
    #             print(f"Joint {i+1}: {j:.2f} degrees")

    #         index = int(input("Enter joint index to move (1-6): ")) - 1
    #         angle = float(input(f"Enter new angle for Joint {index+1}: "))

    #         updated_joints = current_joints.copy()
    #         updated_joints[index] = angle

    #         send_new_joints(updated_joints, client_socket)

    #         # Receive response from RAPID
    #         response = client_socket.recv(1024).decode()  # Read up to 1024 bytes
    #         print("Received from robot:", response)

    #     except KeyboardInterrupt:
    #         print("\nClosing connection...")
    #         break
    #     except Exception as e:
    #         print(f"Error: {e}")

    # Close socket before exiting
    client_socket.close()
    print("Socket closed.")
