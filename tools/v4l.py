import cv2

video_device = "/dev/v4l/by-id/usb-fushicai_usbtv007_300000000002-video-index0"


def capture_still_frame():
    cap = cv2.VideoCapture(video_device)
    w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
    h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
    print(w, h)

    # Check if camera was opened correctly
    if not (cap.isOpened()):
        print("Could not open video device")

    # For some reason the brightness can only be set after reading one frame
    ret, frame = cap.read()
    # cap.set(cv2.CAP_PROP_BRIGHTNESS, 350)

    for i in range(10):
        ret, frame = cap.read()

    cap.release()
    return frame


def capture_video():
    cap = cv2.VideoCapture(video_device)

    if not (cap.isOpened()):
        print("Could not open video device")

    # For some reason the brightness can only be set after reading one frame
    ret, frame = cap.read()
    # cap.set(cv2.CAP_PROP_BRIGHTNESS, 420)

    while (True):
        ret, frame = cap.read()
        cv2.imshow("preview", frame)
        # Waits for a user input to quit the application
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    cap.release()
    return frame
