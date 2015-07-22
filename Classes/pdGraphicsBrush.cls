VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "pdGraphicsBrush"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'***************************************************************************
'PhotoDemon Graphics Fill ("Brush" in GDI/GDI+ parlance) Class
'Copyright 2014-2015 by Tanner Helland
'Created: 30/June/15 (but assembled from many bits written earlier)
'Last updated: 16/July/15
'Last update: convert the class's string output to use XML instead of the old pipe-delimited technique
'
'This class manages a single GDI+ WAPI brush instance.  (Brushes are used to fill shapes/paths.)
'
'At present, it is primarily based on the capabilities of GDI+.  This may change going forward, but because GDI+ provides
' a nice baseline feature set, we started with it.
'
'All source code in this file is licensed under a modified BSD license.  This means you may use the code in your own
' projects IF you provide attribution.  For more information, please visit http://photodemon.org/about/license/
'
'***************************************************************************

Option Explicit

'Brushes support a *lot* of internal settings.
Public Enum PD_GRAPHICS_BRUSH_SETTINGS
    pgbs_BrushMode = 0
    pgbs_PrimaryColor = 1
    pgbs_PrimaryOpacity = 2
    pgbs_PatternID = 3
    pgbs_PatternColor1 = 4
    pgbs_PatternColor1Opacity = 5
    pgbs_PatternColor2 = 6
    pgbs_PatternColor2Opacity = 7
End Enum

#If False Then
    Const pgbs_BrushMode = 0, pgbs_PrimaryColor = 1, pgbs_PrimaryOpacity = 2, pgbs_PatternID = 3, pgbs_PatternColor1 = 4
    Const pgbs_PatternColor1Opacity = 5, pgbs_PatternColor2 = 6, pgbs_PatternColor2Opacity = 7
#End If

'Current brush mode (solid fill, gradient, texture, etc)
Private m_BrushMode As Long

'Solid brush settings
Private m_PrimaryColor As Long
Private m_PrimaryOpacity As Single

'Pattern brush settings
Private m_PatternID As Long
Private m_PatternColor1 As Long
Private m_PatternColor1Opacity As Single
Private m_PatternColor2 As Long
Private m_PatternColor2Opacity As Single

'This class is capable of serializing itself to/from XML strings
Private cSerialize As pdParamXML

'Gradient brush settings (TBD)

'Texture brush settings (TBD)

'Get/set individual settings by enum type
Public Function getBrushProperty(ByVal propID As PD_GRAPHICS_BRUSH_SETTINGS) As Variant
    
    Select Case propID
        
        Case pgbs_BrushMode
            getBrushProperty = m_BrushMode
        
        Case pgbs_PrimaryColor
            getBrushProperty = m_PrimaryColor
            
        Case pgbs_PrimaryOpacity
            getBrushProperty = m_PrimaryOpacity
            
        Case pgbs_PatternID
            getBrushProperty = m_PatternID
            
        Case pgbs_PatternColor1
            getBrushProperty = m_PatternColor1
            
        Case pgbs_PatternColor1Opacity
            getBrushProperty = m_PatternColor1Opacity
            
        Case pgbs_PatternColor2
            getBrushProperty = m_PatternColor2
            
        Case pgbs_PatternColor2Opacity
            getBrushProperty = m_PatternColor2Opacity
            
    End Select
    
End Function

Public Sub setBrushProperty(ByVal propID As PD_GRAPHICS_BRUSH_SETTINGS, ByVal newSetting As Variant)
    
    Select Case propID
        
        Case pgbs_BrushMode
            m_BrushMode = CLng(newSetting)
        
        Case pgbs_PrimaryColor
            m_PrimaryColor = CLng(newSetting)
            
        Case pgbs_PrimaryOpacity
            m_PrimaryOpacity = CDbl(newSetting)
            
        Case pgbs_PatternID
            m_PatternID = CLng(newSetting)
            
        Case pgbs_PatternColor1
            m_PatternColor1 = CLng(newSetting)
            
        Case pgbs_PatternColor1Opacity
            m_PatternColor1Opacity = CDbl(newSetting)
            
        Case pgbs_PatternColor2
            m_PatternColor2 = CLng(newSetting)
            
        Case pgbs_PatternColor2Opacity
            m_PatternColor2Opacity = CDbl(newSetting)
            
    End Select
    
End Sub

'For interop purposes, brushes are often passed around PD as strings.  Any brush can be perfectly re-created from just this string.
Public Function getBrushAsString() As String
    
    With cSerialize
        .Reset 1#
        .addParam "BrushMode", m_BrushMode
        .addParam "PrimaryColor", m_PrimaryColor
        .addParam "PrimaryOpacity", m_PrimaryOpacity
        .addParam "PatternID", m_PatternID
        .addParam "PatternColor1", m_PatternColor1
        .addParam "PatternColor1Opacity", m_PatternColor1Opacity
        .addParam "PatternColor2", m_PatternColor2
        .addParam "PatternColor2Opacity", m_PatternColor2Opacity
    End With
    
    getBrushAsString = cSerialize.getParamString
    
End Function

Public Sub createBrushFromString(ByRef srcString As String)
    
    'If the string is empty, prep a default object
    If Len(srcString) = 0 Then
        
        m_BrushMode = 0
        m_PrimaryColor = vbBlack
        m_PrimaryOpacity = 100
        m_PatternID = 0
        m_PatternColor1 = vbBlack
        m_PatternColor1Opacity = 100
        m_PatternColor2 = vbWhite
        m_PatternColor2Opacity = 100
        
    Else

        With cSerialize
            .setParamString srcString
            m_BrushMode = .GetLong("BrushMode", 0)
            m_PrimaryColor = .GetLong("PrimaryColor", vbBlack)
            m_PrimaryOpacity = .GetDouble("PrimaryOpacity", 100)
            m_PatternID = .GetLong("PatternID", 0)
            m_PatternColor1 = .GetLong("PatternColor1", vbBlack)
            m_PatternColor1Opacity = .GetDouble("PatternColor1Opacity", 100)
            m_PatternColor2 = .GetLong("PatternColor2", vbWhite)
            m_PatternColor2Opacity = .GetDouble("PatternColor2Opacity", 100)
        End With
        
    End If
    
End Sub

'Return an actual GDI+ brush handle matching the current settings.
' Note that the caller is responsible for freeing that handle once done.
Public Function getBrushHandle() As Long
    
    Select Case m_BrushMode
    
        'Solid fill
        Case 0
            getBrushHandle = GDI_Plus.getGDIPlusSolidBrushHandle(m_PrimaryColor, m_PrimaryOpacity * 2.55)
        
        'Pattern fill
        Case 1
            Dim tmpOpacityModifier As Double
            tmpOpacityModifier = m_PrimaryOpacity / 100
            getBrushHandle = GDI_Plus.getGDIPlusPatternBrushHandle(m_PatternID, m_PatternColor1, m_PatternColor1Opacity * 2.55 * tmpOpacityModifier, m_PatternColor2, m_PatternColor2Opacity * 2.55 * tmpOpacityModifier)
        
        'Gradient fill
        Case 2
            getBrushHandle = 0
        
        'Texture fill
        Case 3
            getBrushHandle = 0
    
    End Select
    
End Function

'Helper function to simplify brush destruction
Public Sub releaseBrushHandle(ByVal srcBrush As Long)
    GDI_Plus.releaseGDIPlusBrush srcBrush
End Sub

Private Sub Class_Initialize()
    
    'Prep a string serializer
    Set cSerialize = New pdParamXML
    
End Sub