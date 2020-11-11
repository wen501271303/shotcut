/*
 * Copyright (c) 2018-2020 Meltytech, LLC
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import org.shotcut.qml 1.0
import QtQuick.Controls 2.12
import Shotcut.Controls 1.0
import QtQuick.Window 2.2
import 'Keyframes.js' as Logic

Rectangle {
    id: keyframeRoot
    property int position: 0
    property int interpolation: KeyframesModel.LinearInterpolation
    property bool isSelected: false
    property string name: ''
    property double value
    property int parameterIndex
    property bool isCurve: false
    property int trackHeight: Logic.trackHeight(isCurve)
    property double minimum: 0.0
    property double maximum: 1.0
    property double trackValue: (0.5 - (value - minimum) / (maximum - minimum)) * (trackHeight - height - 2.0 * border.width)
    property double minDragX: activeClip.x - width/2
    property double maxDragX: activeClip.x + activeClip.width - width/2
    property double minDragY: activeClip.y - width/2
    property double maxDragY: activeClip.y + activeClip.height - width/2

    signal clicked(var keyframe, var mouse)
    signal otherClicked()

    SystemPalette { id: activePalette }

    x: position * timeScale - width/2
    anchors.verticalCenter: parameterRoot.verticalCenter
    anchors.verticalCenterOffset: isCurve ? trackValue : 0
    height: 10
    width: height
    color: isSelected? 'red' : activePalette.buttonText
    border.color: activePalette.button
    border.width: 1
    radius: (interpolation === KeyframesModel.SmoothInterpolation)? height/2 : 0 // circle for smooth
    rotation: (interpolation === KeyframesModel.LinearInterpolation)? 45 : 0    // diamond for linear

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: parent.clicked(keyframeRoot, mouse)
    }
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onClicked: producer.position = position
        onDoubleClicked: removeMenuItem.remove(parameterIndex, index)
        drag {
            target: parent
            axis: isCurve? Drag.XAndYAxis : Drag.XAxis
            threshold: 0
            minimumX: minDragX
            maximumX: maxDragX
            minimumY: minDragY
            maximumY: maxDragY
        }
        onPressed: {
            parent.clicked(keyframeRoot, mouse)
            if (isCurve) {
               if (mouse.modifiers & Qt.ControlModifier)
                   drag.axis = Drag.YAxis
               else if (mouse.modifiers & Qt.AltModifier)
                   drag.axis = Drag.XAxis
               else
                   drag.axis = Drag.XAndYAxis
           }
        }
        onEntered: if (isCurve) parent.anchors.verticalCenter = undefined
        onReleased: if (isCurve) parent.anchors.verticalCenter = parameterRoot.verticalCenter
        onPositionChanged: {
            var newPosition = Math.round(parent.x / timeScale + (parent.width/2))
            if (newPosition !== keyframeRoot.position)
                parameters.setPosition(parameterIndex, index, newPosition - (filter.in - producer.in))
            if (isCurve) {
                var trackValue = Math.min(Math.max(0, 1.0 - parent.y / (parameterRoot.height - parent.height)), 1.0)
                trackValue = minimum + trackValue * (maximum - minimum)
                parameters.setKeyframe(parameterIndex, trackValue, newPosition - (filter.in - producer.in), interpolation)
            }
        }
    }

    ToolTip {
        id: tooltip
        text: name
    }
}
