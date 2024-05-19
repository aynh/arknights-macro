#!/usr/bin/python -m pipenv run python

import pyautogui

n = 0
while n < 10:
    pyautogui.sleep(3)
    try:
        xy = pyautogui.locateOnScreen('img/visit-next.png', confidence=0.5, grayscale=True)
        pyautogui.click(xy)
    except pyautogui.ImageNotFoundException:
        pass
    else:
        n += 1
