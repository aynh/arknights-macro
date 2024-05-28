def main(x1, y1, x2, y2, name):
    import os

    from PIL import ImageGrab
    from time import sleep

    sleep(3)
    image = ImageGrab.grab((x1, y1, x2, y2))

    os.chdir(os.path.dirname(__file__))
    image.save(f"../assets/images/{name}.png")

    print([x1, y1, x2, y2])


if __name__ == "__main__":
    import sys

    main(*map(int, sys.argv[1:5]), sys.argv[5])
