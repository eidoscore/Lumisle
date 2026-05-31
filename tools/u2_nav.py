"""Navigate Lumisle from launch to the game board, then read the board."""
import sys, time
import uiautomator2 as u2

SERIAL = "ytjjkbi7bucyjzyl"

def main():
    d = u2.connect(SERIAL)
    d.app_stop("com.eidoscore.lumisle")
    time.sleep(1)
    d.app_start("com.eidoscore.lumisle")
    time.sleep(6)
    # Main menu: tap "Main" (Play) button ~ center, y~1070 device.
    d.click(540, 1070)
    time.sleep(3)
    # Level map: tap "Level 1" button ~ y 1130.
    d.click(540, 1130)
    time.sleep(3)
    print("navigated to game")

if __name__ == "__main__":
    main()
