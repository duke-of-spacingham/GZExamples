import cv2
import mediapipe as mp
import socket

def send_coord_udp(x, y, z):
    SERVER_HOST = '127.0.0.1'
    SERVER_PORT = 50000
    
    soc = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    #soc.bind((SERVER_HOST, SERVER_PORT))
    msg = str(index_finger_tip.x).encode(encoding="utf-8")
    soc.sendto(msg, (SERVER_HOST, SERVER_PORT))

def send_movement(soc, x_movement):
    
    #with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as soc:
    #soc.connect((SERVER_HOST, SERVER_PORT))
    #message = "("+ str(index_finger_tip.x)  +","+ str(index_finger_tip.y) +","+ str(index_finger_tip.z) +")"
    message = str(x_movement) + "\n"
    soc.sendall(message.encode())

def main(sock):
    # Initialize MediaPipe Hands module
    mp_hands = mp.solutions.hands
    hands = mp_hands.Hands()

    # Initialize MediaPipe Drawing module for drawing landmarks
    mp_drawing = mp.solutions.drawing_utils

    # Open a video capture object (0 for the default camera)
    cap = cv2.VideoCapture(0)

    last_x = 0
    print("ok, start.")
    while cap.isOpened():
        ret, frame = cap.read()
        
        if not ret:
            continue
        
        # Convert the frame to RGB format
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Process the frame to detect hands
        results = hands.process(frame_rgb)
        
        # Check if hands are detected
        if results.multi_hand_landmarks:
            #Take the right hand
            if results.multi_handedness[0].classification[0].label == 'Left' :
                hand_landmarks = results.multi_hand_landmarks[0]
            elif len(results.multi_handedness) > 1 and results.multi_handedness[1].classification[0].label == 'Left':
                hand_landmarks = results.multi_hand_landmarks[1]
            else : 
                hand_landmarks = None
                
            #If found the hand, draw model and Report meaningful finger location changes
            if hand_landmarks != None:
                index_finger_tip = hand_landmarks.landmark[mp_hands.HandLandmark.INDEX_FINGER_TIP]
                
                #print(abs(last_x - index_finger_tip.x))
                if abs(last_x - index_finger_tip.x) > 0.01:
                    #print("("+ str(index_finger_tip.x)  +","+ str(index_finger_tip.y) +","+ str(index_finger_tip.z) +")")
                    send_movement(soc, last_x - index_finger_tip.x)
                    last_x = index_finger_tip.x
                
                # Draw landmarks on the frame
                #mp_drawing.draw_landmarks(frame, hand_landmarks, mp_hands.HAND_CONNECTIONS)
        
        # Display the frame with hand landmarks
        #cv2.imshow('Hand Recognition', frame)
        
        # Exit when 'q' is pressed (doesn't work when the window is not shown, use CTRL-C in the meanwhile)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    # Release the video capture object and close the OpenCV windows
    cap.release()
    cv2.destroyAllWindows()
    
try:
    SERVER_HOST = '127.0.0.1'
    SERVER_PORT = 50000
    soc = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    soc.connect((SERVER_HOST, SERVER_PORT))
    
    main(soc)
finally:
    soc.close()