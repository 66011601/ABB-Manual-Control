import socket
import ast
import time
import keyboard
import os

# Define ABB robot's virtual controller address
HOST = "127.0.0.1"  # Localhost (RobotStudio)
PORT = 6000         # Port matching RAPID code
INCREMENT = 1.0
SLEEP = 0.1  # Seconds

def get_current_joints(client_socket):
    data = client_socket.recv(1024).decode()
    joints = ast.literal_eval(data)
    return joints

def get_current_positions(client_socket):
    data = client_socket.recv(1024).decode()
    pos = ast.literal_eval(data)
    return pos

def get_respond(client_socket):
    respond = client_socket.recv(1024).decode()
    return respond

def send_new_joints(joints, client_socket):
    message = ",".join(str(j) for j in joints)
    client_socket.sendall(message.encode())
    print(f"Sent updated joint targets: {message}")

def send_new_positions(pos, client_socket):
    message = ",".join(str(p) for p in pos)
    client_socket.sendall(message.encode())
    print(f"Sent updated positions: {message}")

def send_moveType(moveType, client_socket):
    message = str(moveType)
    client_socket.sendall(message.encode())
    print(f"Sent moving type: {message}")
    respond = get_respond(client_socket)
    if respond == "MOVE TO CHECKING" :
        time.sleep(1)
        send_moveType(moveType, client_socket)

def clear_terminal():
    os.system('cls' if os.name == 'nt' else 'clear')

def display_joints(joints):
    clear_terminal()
    print("Move Joints\n")
    for i, val in enumerate(joints):
        print(f"Joint {i+1} : {val:.2f}")
    print("\n[Hold keys 1-6 to move joints, press Q to quit]")
    print("\n[Press keys + to add, press - to minus, press s to send, press l to change to linear mode]")

def display_positons(pos):
    clear_terminal()
    index = ["X", "Y", "Z"]
    print("Move Linear\n")
    for i, val in enumerate(pos):
        print(f"Position {index[i]} : {val:.2f}")
    print("\n[Hold keys 1-3 to move XYZ, press Q to quit]")
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
        moving_type = ["JOINT", "LINEAR"]
        moving_option = int(input("What kind of moving type you like (1 : Joint, 2 : Linear) : ")) - 1
        send_moveType(moving_type[moving_option], client_socket)
        while True:
            if moving_type[moving_option] == "JOINT" : current_joints = get_current_joints(client_socket)
            elif moving_type[moving_option] == "LINEAR" : current_positions = get_current_positions(client_socket)
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

                elif moving_type[moving_option] == "LINEAR" :
                    display_positons(current_positions)

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
