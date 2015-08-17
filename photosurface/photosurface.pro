TEMPLATE = app

QT += qml quick websockets
qtHaveModule(widgets): QT += widgets
SOURCES += main.cpp
RESOURCES += \
    twitaroid.qrc

target.path = $$[QT_INSTALL_EXAMPLES]/quick/demos/photosurface
INSTALLS += target
ICON = resources/icon.png
macx: ICON = resources/photosurface.icns
win32: RC_FILE = resources/photosurface.rc

