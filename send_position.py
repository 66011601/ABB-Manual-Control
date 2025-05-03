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

def send_new_joints(joints, client_socket):
    message = ",".join(str(j) for j in joints)
    client_socket.sendall(message.encode())
    print(f"Sent updated joint targets: {message}")

def clear_terminal():
    os.system('cls' if os.name == 'nt' else 'clear')

def display_joints(joints):
    clear_terminal()
    for i, val in enumerate(joints):
        print(f"Joint {i+1} : {val:.2f}")
    print("\n[Hold keys 1-6 to move joints, press Q to quit]")
    print("\n[Press keys + to add, press - to minus, press s to send]")

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
        current_joints = get_current_joints(client_socket)
        sign = 1
        while True:
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
