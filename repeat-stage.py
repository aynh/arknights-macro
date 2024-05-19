#!/usr/bin/python -m pipenv run python

import sys


def repeat(n):
    import pyautogui

    sequence = [
        ("img/start-1-a.png", "img/start-1-b.png", "img/start-1-c.png"),
        ("img/start-2-a.png", "img/start-2-b.png"),
        "img/complete.png",
    ]

    def try_click(image_or_images):
        if isinstance(image_or_images, tuple):
            return any(try_click(image) for image in image_or_images)

        pyautogui.sleep(1)
        try:
            xy = pyautogui.locateOnScreen(image_or_images, confidence=0.8, grayscale=True)
            pyautogui.click(xy, duration=2.5)
            return True
        except pyautogui.ImageNotFoundException:
            return False

    idx = 0
    while (idx // len(sequence)) < n:
        if try_click(sequence[idx % len(sequence)]):
            idx += 1

if len(sys.argv) == 1:
    n = int(input('n: '))
else:
    n = int(sys.argv[1])
    
repeat(n)
