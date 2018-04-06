-- base
import Control.Concurrent    (threadDelay)
import Control.Monad         (forM, forM_, when)
import Data.Char             (isAscii)
import Data.List             (intercalate, isPrefixOf)
import Foreign.C.String      (peekCString, withCString)
import Foreign.Marshal.Alloc (alloca)
import Foreign.Marshal.Array (peekArray)
import Foreign.Ptr           (Ptr, nullPtr)
import Foreign.Storable      (Storable(..))

-- HUnit
import Test.HUnit ((@?=), (@?), assertBool, assertFailure)

-- test-framework
import Test.Framework (Test, defaultMain, testGroup)

-- test-framework-hunit
import Test.Framework.Providers.HUnit (testCase)

-- bindings-GLFW
import Bindings.GLFW

--------------------------------------------------------------------------------

main :: IO ()
main = do
    cb <- mk'GLFWerrorfun $ \errnum p'desc -> do
        desc <- if p'desc /= nullPtr
                  then peekCString p'desc
                  else return "unknown error"
        putStrLn $ unwords ["###", "error:", show errnum, show desc]
    _ <- c'glfwSetErrorCallback cb

    -- uncomment next line to test error callback
    -- _ <- c'glfwGetPrimaryMonitor

    _ <- c'glfwInit

    p'mon <- c'glfwGetPrimaryMonitor

    c'glfwWindowHint c'GLFW_VISIBLE c'GL_FALSE
    p'win <- withCString "bindings-GLFW test" $ \p'title ->
      c'glfwCreateWindow 100 100 p'title nullPtr nullPtr
    c'glfwMakeContextCurrent p'win

    defaultMain $ tests p'mon p'win

    -- TODO because of how defaultMain works, this code is not reached
    c'glfwDestroyWindow p'win
    c'glfwTerminate

--------------------------------------------------------------------------------

versionMajor, versionMinor, versionRevision :: Int
versionMajor    = 3
versionMinor    = 2
versionRevision = 1

giveItTime :: IO ()
giveItTime = threadDelay 500000

joysticks :: Num a => [a]
joysticks =
    [ c'GLFW_JOYSTICK_1
    , c'GLFW_JOYSTICK_2
    , c'GLFW_JOYSTICK_3
    , c'GLFW_JOYSTICK_4
    , c'GLFW_JOYSTICK_5
    , c'GLFW_JOYSTICK_6
    , c'GLFW_JOYSTICK_7
    , c'GLFW_JOYSTICK_8
    , c'GLFW_JOYSTICK_9
    , c'GLFW_JOYSTICK_10
    , c'GLFW_JOYSTICK_11
    , c'GLFW_JOYSTICK_12
    , c'GLFW_JOYSTICK_13
    , c'GLFW_JOYSTICK_14
    , c'GLFW_JOYSTICK_15
    , c'GLFW_JOYSTICK_16
    ]

between :: Ord a => a -> (a,a) -> Bool
between n (l,h) = n >= l && n <= h

videoModeLooksValid :: C'GLFWvidmode -> Bool
videoModeLooksValid vm = and
    [ c'GLFWvidmode'width       vm `between` (0,4000)
    , c'GLFWvidmode'height      vm `between` (0,4000)
    , c'GLFWvidmode'redBits     vm `between` (0,32)
    , c'GLFWvidmode'greenBits   vm `between` (0,32)
    , c'GLFWvidmode'blueBits    vm `between` (0,32)
    , c'GLFWvidmode'refreshRate vm `between` (0,120)
    ]

--------------------------------------------------------------------------------

tests :: Ptr C'GLFWmonitor -> Ptr C'GLFWwindow -> [Test]
tests p'mon p'win =
    [ testGroup "Initialization and version information"
      [ testCase "glfwGetVersion"       test_glfwGetVersion
      , testCase "glfwGetVersionString" test_glfwGetVersionString
      ]
    , testGroup "Monitor handling"
      [ testCase "glfwGetMonitors"              test_glfwGetMonitors
      , testCase "glfwGetPrimaryMonitor"        test_glfwGetPrimaryMonitor
      , testCase "glfwGetMonitorPos"          $ test_glfwGetMonitorPos p'mon
      , testCase "glfwGetMonitorPhysicalSize" $ test_glfwGetMonitorPhysicalSize p'mon
      , testCase "glfwGetMonitorName"         $ test_glfwGetMonitorName p'mon
      , testCase "glfwGetVideoModes"          $ test_glfwGetVideoModes p'mon
      , testCase "glfwGetVideoMode"           $ test_glfwGetVideoMode p'mon
      , testCase "glfwGetGammaRamp"           $ test_glfwGetGammaRamp p'mon
      -- , testCase "setGamma"                   $ test_glfwSetGamma p'mon
      -- , testCase "gamma ramp"                 $ test_glfwGamma_ramp p'mon
      ]
    , testGroup "Window handling"
      [ testCase "glfwDefaultWindowHints"       test_glfwDefaultWindowHints
      , testCase "glfwGetWindowAttrib"        $ test_glfwGetWindowAttrib p'win
      , testCase "window close flag"          $ test_window_close_flag p'win
      , testCase "glfwSetWindowTitle"         $ test_glfwSetWindowTitle p'win
      , testCase "window pos"                 $ test_window_pos p'win
      , testCase "window size"                $ test_window_size p'win
      , testCase "glfwGetFramebufferSize"     $ test_glfwGetFramebufferSize p'win
      , testCase "iconification"              $ test_iconification p'win
      -- , testCase "show/hide"                  $ test_show_hide p'win
      , testCase "glfwGetWindowMonitor"       $ test_glfwGetWindowMonitor p'win p'mon
      , testCase "glfwSetWindowMonitor"       $ test_glfwSetWindowMonitor p'win p'mon
      , testCase "glfwSetWindowIcon"          $ test_glfwSetWindowIcon p'win
      , testCase "glfwMaximizeWindow"         $ test_glfwMaximizeWindow p'win
      , testCase "glfwSetWindowSizeLimits"    $ test_glfwSetWindowSizeLimits p'win
      , testCase "glfwSetWindowAspectRatio"   $ test_glfwSetWindowAspectRatio p'win
      , testCase "glfwFocusWindow"            $ test_glfwFocusWindow p'win
      , testCase "cursor pos"                 $ test_cursor_pos p'win
      , testCase "glfwPollEvents"               test_glfwPollEvents
      -- This test is commented out because it just blocks forever (which is the intended behaviour):
      -- , testCase "glfwWaitEvents"               test_glfwWaitEvents
      , testCase "glfwWaitEventsTimeout"        test_glfwWaitEventsTimeout
      ]
    , testGroup "Input handling"
      [ testCase "glfwJoystickPresent"    test_glfwJoystickPresent
      , testCase "glfwGetJoystickAxes"    test_glfwGetJoystickAxes
      , testCase "glfwGetJoystickButtons" test_glfwGetJoystickButtons
      , testCase "glfwGetJoystickName"    test_glfwGetJoystickName
      , testCase "glfwGetKeyName"         test_glfwGetKeyName
      ]
    , testGroup "Time"
      [ testCase "glfwGetTime" test_glfwGetTime
      , testCase "glfwSetTime" test_glfwSetTime
      ]
    , testGroup "Timers"
      [ testCase "glfwGetTimerValue"         test_glfwGetTimerValue
      , testCase "glfwSetTimerFrequency"     test_glfwGetTimerFrequency
      ]
    , testGroup "Context"
      [ testCase "glfwGetCurrentContext"  $ test_glfwGetCurrentContext p'win
      , testCase "glfwSwapBuffers"        $ test_glfwSwapBuffers p'win
      , testCase "glfwSwapInterval"         test_glfwSwapInterval
      , testCase "glfwExtensionSupported"   test_glfwExtensionSupported
      ]
    , testGroup "Clipboard"
      [ testCase "clipboard" $ test_clipboard p'win
      ]
    , testGroup "Vulkan"
      [ testCase "glfwVulkanSupported"                          test_glfwVulkanSupported
      , testCase "glfwGetRequiredInstanceExtensions"            test_glfwGetRequiredInstanceExtensions
      , testCase "glfwGetInstanceProcAddress"                   test_glfwGetInstanceProcAddress
      , testCase "glfwGetPhysicalDevicePresentationSupport"     test_glfwGetPhysicalDevicePresentationSupport
      , testCase "glfwCreateWindowSurface"                    $ test_glfwCreateWindowSurface p'win
      ]
    ]

--------------------------------------------------------------------------------

test_glfwGetVersion :: IO ()
test_glfwGetVersion =
    alloca $ \p'v0 ->
    alloca $ \p'v1 ->
    alloca $ \p'v2 -> do
        c'glfwGetVersion p'v0 p'v1 p'v2
        v0 <- peek p'v0
        v1 <- peek p'v1
        v2 <- peek p'v2
        v0 @?= fromIntegral versionMajor
        v1 @?= fromIntegral versionMinor
        v2 @?= fromIntegral versionRevision

test_glfwGetVersionString :: IO ()
test_glfwGetVersionString = do
    p'vs <- c'glfwGetVersionString
    if p'vs == nullPtr
      then assertFailure ""
      else do
          vs <- peekCString p'vs
          assertBool "" $ v `isPrefixOf` vs
        where
          v = intercalate "." $ map show [versionMajor, versionMinor, versionRevision]

--------------------------------------------------------------------------------

test_glfwGetMonitors :: IO ()
test_glfwGetMonitors =
    alloca $ \p'n -> do
        p'mons <- c'glfwGetMonitors p'n
        n <- peek p'n
        if p'mons == nullPtr || n <= 0
          then assertFailure ""
          else do
              mons <- peekArray (fromIntegral n) p'mons
              assertBool "" $ not $ null mons

test_glfwGetPrimaryMonitor :: IO ()
test_glfwGetPrimaryMonitor = do
    p'mon <- c'glfwGetPrimaryMonitor
    assertBool "" $ p'mon /= nullPtr

test_glfwGetMonitorPos :: Ptr C'GLFWmonitor -> IO ()
test_glfwGetMonitorPos p'mon =
    alloca $ \p'x ->
    alloca $ \p'y -> do
        c'glfwGetMonitorPos p'mon p'x p'y
        x <- peek p'x
        y <- peek p'y
        assertBool "" $ x >= 0
        assertBool "" $ y >= 0

test_glfwGetMonitorPhysicalSize :: Ptr C'GLFWmonitor -> IO ()
test_glfwGetMonitorPhysicalSize p'mon =
    alloca $ \p'w ->
    alloca $ \p'h -> do
        c'glfwGetMonitorPhysicalSize p'mon p'w p'h
        w <- peek p'w
        h <- peek p'h
        assertBool "" $ w `between` (0, 1000)
        assertBool "" $ h `between` (0,  500)

test_glfwGetMonitorName :: Ptr C'GLFWmonitor -> IO ()
test_glfwGetMonitorName p'mon = do
    p'name <- c'glfwGetMonitorName p'mon
    if p'name == nullPtr
      then assertFailure ""
      else do
          name <- peekCString p'name
          assertBool "" $ length name `between` (0, 20)
          assertBool "" $ all isAscii name

test_glfwGetVideoModes :: Ptr C'GLFWmonitor -> IO ()
test_glfwGetVideoModes p'mon =
    alloca $ \p'n -> do
        p'vms <- c'glfwGetVideoModes p'mon p'n
        n <- fromIntegral `fmap` peek p'n
        if p'vms == nullPtr || n <= 0
          then assertFailure ""
          else do
              vms <- peekArray n p'vms
              assertBool "" $ all videoModeLooksValid vms

test_glfwGetVideoMode :: Ptr C'GLFWmonitor -> IO ()
test_glfwGetVideoMode p'mon = do
    p'vm <- c'glfwGetVideoMode p'mon
    if p'vm == nullPtr
      then assertFailure ""
      else do
          vm <- peek p'vm
          assertBool "" $ videoModeLooksValid vm

test_glfwGetGammaRamp :: Ptr C'GLFWmonitor -> IO ()
test_glfwGetGammaRamp p'mon = do
    p'gr <- c'glfwGetGammaRamp p'mon
    if p'gr == nullPtr
      then assertFailure ""
      else do
          gr <- peek p'gr
          let p'rs = c'GLFWgammaramp'red   gr
              p'gs = c'GLFWgammaramp'green gr
              p'bs = c'GLFWgammaramp'blue  gr
              cn   = c'GLFWgammaramp'size  gr
              n    = fromIntegral cn
          if nullPtr `elem` [p'rs, p'gs, p'bs]
            then assertFailure ""
            else do
                rs <- peekArray n p'rs
                gs <- peekArray n p'gs
                bs <- peekArray n p'bs
                let rsl = length rs
                    gsl = length gs
                    bsl = length bs
                assertBool "" $ rsl > 0 && rsl == gsl && gsl == bsl

--------------------------------------------------------------------------------

test_glfwDefaultWindowHints :: IO ()
test_glfwDefaultWindowHints =
    c'glfwDefaultWindowHints

test_window_close_flag :: Ptr C'GLFWwindow -> IO ()
test_window_close_flag p'win = do
    r0 <- c'glfwWindowShouldClose p'win
    r0 @?= c'GL_FALSE

    c'glfwSetWindowShouldClose p'win c'GL_TRUE
    r1 <- c'glfwWindowShouldClose p'win
    r1 @?= c'GL_TRUE

    c'glfwSetWindowShouldClose p'win c'GL_FALSE
    r2 <- c'glfwWindowShouldClose p'win
    r2 @?= c'GL_FALSE

test_glfwSetWindowTitle :: Ptr C'GLFWwindow -> IO ()
test_glfwSetWindowTitle p'win =
    withCString "some new title" $
      c'glfwSetWindowTitle p'win

-- This is a little strange. Depending on your window manager, etc, after
-- setting the window position to (x,y), the actual new window position might
-- be (x+5,y+5) due to borders. So we just check for consistency.
test_window_pos :: Ptr C'GLFWwindow -> IO ()
test_window_pos p'win = do
    let x = 17
        y = 37
        xoff = 53
        yoff = 149
    (x0, y0, dx0, dy0) <- setGet  x        y
    (x1, y1, dx1, dy1) <- setGet (x+xoff) (y+yoff)
    dx0 @?= dx1
    dy0 @?= dy1
    x1 - x0 @?= xoff
    y1 - y0 @?= yoff
  where
    setGet :: Int -> Int -> IO (Int, Int, Int, Int)
    setGet x0 y0 = do
        c'glfwSetWindowPos p'win (fromIntegral x0) (fromIntegral y0)
        giveItTime
        alloca $ \p'x1 ->
          alloca $ \p'y1 -> do
              c'glfwGetWindowPos p'win p'x1 p'y1
              x1 <- fromIntegral `fmap` peek p'x1
              y1 <- fromIntegral `fmap` peek p'y1
              let (dx, dy) = (x0-x1, y0-y1)
              return (x1, y1, dx, dy)

test_window_size :: Ptr C'GLFWwindow -> IO ()
test_window_size p'win = do
    let w = 177
        h = 372
    c'glfwSetWindowSize p'win w h
    giveItTime
    alloca $ \p'w' ->
      alloca $ \p'h' -> do
          c'glfwGetWindowSize p'win p'w' p'h'
          w' <- fromIntegral `fmap` peek p'w'
          h' <- fromIntegral `fmap` peek p'h'
          w' @?= w
          h' @?= h

test_glfwGetFramebufferSize :: Ptr C'GLFWwindow -> IO ()
test_glfwGetFramebufferSize p'win =
    alloca $ \p'w  ->
    alloca $ \p'h  ->
    alloca $ \p'fw ->
    alloca $ \p'fh -> do
        c'glfwGetWindowSize      p'win p'w  p'h
        c'glfwGetFramebufferSize p'win p'fw p'fh
        w  <- peek p'w
        h  <- peek p'h
        fw <- peek p'fw
        fh <- peek p'fh
        ((fw `mod` w) == 0) @? "Framebuffer width multiple of window's"
        ((fh `mod` h) == 0) @? "Framebuffer height multiple of window's"

test_iconification :: Ptr C'GLFWwindow -> IO ()
test_iconification p'win = do
    r0 <- c'glfwGetWindowAttrib p'win c'GLFW_ICONIFIED
    r0 @?= c'GL_FALSE

    c'glfwIconifyWindow p'win
    giveItTime

    r1 <- c'glfwGetWindowAttrib p'win c'GLFW_ICONIFIED
    r1 @?= c'GL_TRUE

    c'glfwRestoreWindow p'win

-- test_show_hide :: Ptr C'GLFWwindow -> IO ()
-- test_show_hide p'win = do
--     v0 <- c'glfwGetWindowAttrib p'win c'GLFW_VISIBLE
--     v0 @?= c'GL_FALSE

--     c'glfwShowWindow p'win
--     giveItTime
--     v1 <- c'glfwGetWindowAttrib p'win c'GLFW_VISIBLE
--     v1 @?= c'GL_TRUE

--     c'glfwHideWindow p'win
--     giveItTime
--     v2 <- c'glfwGetWindowAttrib p'win c'GLFW_VISIBLE
--     v2 @?= c'GL_FALSE

test_glfwGetWindowMonitor :: Ptr C'GLFWwindow -> Ptr C'GLFWmonitor -> IO ()
test_glfwGetWindowMonitor p'win _ = do
    p'mon <- c'glfwGetWindowMonitor p'win
    p'mon @?= nullPtr

test_glfwSetWindowMonitor :: Ptr C'GLFWwindow -> Ptr C'GLFWmonitor -> IO ()
test_glfwSetWindowMonitor p'win _ = do
    c'glfwSetWindowMonitor p'win nullPtr 0 0 100 100 60

test_glfwSetWindowIcon :: Ptr C'GLFWwindow -> IO ()
test_glfwSetWindowIcon p'win = do
    c'glfwSetWindowIcon p'win 0 nullPtr

test_glfwSetWindowSizeLimits :: Ptr C'GLFWwindow -> IO ()
test_glfwSetWindowSizeLimits p'win = do
    c'glfwSetWindowSizeLimits p'win 640 480 1024 768

test_glfwSetWindowAspectRatio :: Ptr C'GLFWwindow -> IO ()
test_glfwSetWindowAspectRatio p'win = do
    c'glfwSetWindowAspectRatio p'win c'GLFW_DONT_CARE c'GLFW_DONT_CARE

test_glfwFocusWindow :: Ptr C'GLFWwindow -> IO ()
test_glfwFocusWindow = c'glfwFocusWindow

-- NOTE: This test seems to fail in X11. This might be due to the asynchronous
-- nature of focus events in X. We may be able to fix it by waiting for the focus
-- event before setting the cursor position.
test_cursor_pos :: Ptr C'GLFWwindow -> IO ()
test_cursor_pos p'win =
    alloca $ \p'w   ->
    alloca $ \p'h   ->
    alloca $ \p'cx' ->
    alloca $ \p'cy' -> do
        c'glfwGetWindowSize p'win p'w p'h
        w <- peek p'w
        h <- peek p'h
        let cx = fromIntegral w / 2
            cy = fromIntegral h / 2
        c'glfwSetCursorPos p'win cx cy
        giveItTime
        c'glfwGetCursorPos p'win p'cx' p'cy'
        cx' <- peek p'cx'
        cy' <- peek p'cy'
        cx' @?= cx
        cy' @?= cy

test_glfwGetWindowAttrib :: Ptr C'GLFWwindow -> IO ()
test_glfwGetWindowAttrib p'win = do
    let pairs =
          [ ( c'GLFW_FOCUSED,    c'GL_FALSE        )
          , ( c'GLFW_ICONIFIED,  c'GL_FALSE        )
          , ( c'GLFW_RESIZABLE,  c'GL_TRUE         )
          , ( c'GLFW_DECORATED,  c'GL_TRUE         )
          , ( c'GLFW_CLIENT_API, c'GLFW_OPENGL_API )
          ]
    rs <- mapM (c'glfwGetWindowAttrib p'win . fst) pairs
    rs @?= map snd pairs

{- NOTE : this test seems to crash on macOSX:
2018-01-15 13:22:30.808 main[96098:4789116] *** Assertion failure in -[_NSCGSWindow setSize:], /BuildRoot/Library/Caches/com.apple.xbs/Sources/AppKit/AppKit-1561.20.106/CGS.subproj/NSCGSWindow.m:1040
2018-01-15 13:22:30.813 main[96098:4789116] *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid parameter not satisfying: size.width >= 0.0 && size.width < (CGFloat)INT_MAX - (CGFloat)INT_MIN && size.height >= 0.0 && size.height < (CGFloat)INT_MAX - (CGFloat)INT_MIN'
*** First throw call stack:
(
	0   CoreFoundation                      0x00007fff5750100b __exceptionPreprocess + 171
	1   libobjc.A.dylib                     0x00007fff7e0dfc76 objc_exception_throw + 48
	2   CoreFoundation                      0x00007fff57506da2 +[NSException raise:format:arguments:] + 98
	3   Foundation                          0x00007fff59613260 -[NSAssertionHandler handleFailureInMethod:object:file:lineNumber:description:] + 193
	4   AppKit                              0x00007fff55530f6b -[_NSCGSWindow setSize:] + 181
	5   AppKit                              0x00007fff55326d92 -[NSWindow _cgsPlaceWindow:] + 54
	6   AppKit                              0x00007fff54b07be4 -[NSWindow _setFrame:updateBorderViewSize:] + 922
	7   AppKit                              0x00007fff54b20087 -[NSWindow _oldPlaceWindow:] + 604
	8   AppKit                              0x00007fff54b1f63a -[NSWindow _setFrameCommon:display:stashSize:] + 3108
	9   AppKit                              0x00007fff54b1ea09 -[NSWindow _setFrame:display:allowImplicitAnimation:stashSize:] + 222
	10  AppKit                              0x00007fff54b1e924 -[NSWindow setFrame:display:] + 67
	11  AppKit                              0x00007fff54c98247 __28-[NSMoveHelper _doAnimation]_block_invoke + 946
	12  AppKit                              0x00007fff54c1304c -[NSScreenDisplayLink _fire] + 298
	13  CoreFoundation                      0x00007fff57484bb4 __CFRUNLOOP_IS_CALLING_OUT_TO_A_TIMER_CALLBACK_FUNCTION__ + 20
	14  CoreFoundation                      0x00007fff57484827 __CFRunLoopDoTimer + 1095
	15  CoreFoundation                      0x00007fff5748432a __CFRunLoopDoTimers + 346
	16  CoreFoundation                      0x00007fff5747b92b __CFRunLoopRun + 2427
	17  CoreFoundation                      0x00007fff5747ad23 CFRunLoopRunSpecific + 483
	18  AppKit                              0x00007fff54c97484 -[NSMoveHelper _doAnimation] + 1556
	19  AppKit                              0x00007fff54caeb3a -[NSMoveHelper _resizeWindow:toFrame:display:] + 389
	20  AppKit                              0x00007fff54c1d752 -[NSWindow setFrame:display:animate:] + 1453
	21  AppKit                              0x00007fff54cadc90 -[NSWindow zoom:] + 982
	22  main                                0x0000000108e5e082 sgo3_info + 122
)
libc++abi.dylib: terminating with uncaught exception of type NSException
-}
test_glfwMaximizeWindow :: Ptr C'GLFWwindow -> IO ()
test_glfwMaximizeWindow p'win = do
    c'glfwMaximizeWindow p'win

test_glfwPollEvents :: IO ()
test_glfwPollEvents =
    c'glfwPollEvents

test_glfwWaitEvents :: IO ()
test_glfwWaitEvents =
    c'glfwWaitEvents

test_glfwWaitEventsTimeout :: IO ()
test_glfwWaitEventsTimeout =
    -- to not slow down the test too much we set the timeout to 0.001 second :
    c'glfwWaitEventsTimeout 0.001

--------------------------------------------------------------------------------

test_glfwJoystickPresent :: IO ()
test_glfwJoystickPresent = do
    _ <- c'glfwJoystickPresent c'GLFW_JOYSTICK_1
    r <- c'glfwJoystickPresent c'GLFW_JOYSTICK_16
    r @?= c'GL_FALSE

test_glfwGetJoystickAxes :: IO ()
test_glfwGetJoystickAxes =
    forM_ joysticks $ \js ->
      alloca $ \p'n -> do
          p'axes <- c'glfwGetJoystickAxes js p'n
          when (p'axes /= nullPtr) $ do
              n <- fromIntegral `fmap` peek p'n
              if n <= 0
                then assertFailure ""
                else do
                    axes <- peekArray n p'axes
                    length axes @?= n

test_glfwGetJoystickButtons :: IO ()
test_glfwGetJoystickButtons =
    forM_ joysticks $ \js ->
      alloca $ \p'n -> do
          p'buttons <- c'glfwGetJoystickButtons js p'n
          when (p'buttons /= nullPtr) $ do
              n <- fromIntegral `fmap` peek p'n
              if n <= 0
                then assertFailure ""
                else do
                    buttons <- peekArray n p'buttons
                    length buttons @?= n

test_glfwGetJoystickName :: IO ()
test_glfwGetJoystickName =
    forM_ joysticks $ \js -> do
        p'name <- c'glfwGetJoystickName js
        when (p'name /= nullPtr) $ do
            name <- peekCString p'name
            assertBool "" $ not $ null name

test_glfwGetKeyName :: IO ()
test_glfwGetKeyName =
    forM_ [c'GLFW_KEY_SLASH, c'GLFW_KEY_PERIOD] $ \k -> do
        p'name <- c'glfwGetKeyName k 0
        when (p'name /= nullPtr) $ do
            name <- peekCString p'name
            assertBool "" $ not $ null name

--------------------------------------------------------------------------------

test_glfwGetTime :: IO ()
test_glfwGetTime = do
    t <- c'glfwGetTime
    assertBool "" $ t > 0

test_glfwSetTime :: IO ()
test_glfwSetTime = do
    let t = 37 :: Double
    c'glfwSetTime (realToFrac t)
    t' <- realToFrac `fmap` c'glfwGetTime
    assertBool "" $ t' `between` (t, t+10)

--------------------------------------------------------------------------------

test_glfwGetTimerValue :: IO ()
test_glfwGetTimerValue = do
    val <- c'glfwGetTimerValue
    assertBool "" $ val > 0

test_glfwGetTimerFrequency :: IO ()
test_glfwGetTimerFrequency = do
    freq <- c'glfwGetTimerFrequency
    assertBool "" $ freq > 0

--------------------------------------------------------------------------------

test_glfwGetCurrentContext :: Ptr C'GLFWwindow -> IO ()
test_glfwGetCurrentContext p'win = do
    p'win' <- c'glfwGetCurrentContext
    p'win' @?= p'win

test_glfwSwapBuffers :: Ptr C'GLFWwindow -> IO ()
test_glfwSwapBuffers =
    c'glfwSwapBuffers

test_glfwSwapInterval :: IO ()
test_glfwSwapInterval =
    c'glfwSwapInterval 1

test_glfwExtensionSupported :: IO ()
test_glfwExtensionSupported = do
    let pairs =
          [ ( "GL_ARB_multisample", c'GL_TRUE  )
          , ( "bogus",              c'GL_FALSE )
          ]
    rs <- forM (map fst pairs) $ \ext ->
      withCString ext c'glfwExtensionSupported
    rs @?= map snd pairs

--------------------------------------------------------------------------------

test_clipboard :: Ptr C'GLFWwindow -> IO ()
test_clipboard p'win = do
    rs <- mapM setGet ss
    rs @?= ss
  where
    ss =
      [ "abc 123 ???"
      , "xyz 456 !!!"
      ]
    setGet s = do
        withCString s $ \p's ->
          c'glfwSetClipboardString p'win p's
        threadDelay 100000  -- Give it a little time
        p's' <- c'glfwGetClipboardString p'win
        if p's' == nullPtr
          then return ""
          else peekCString p's'

--------------------------------------------------------------------------------

test_glfwVulkanSupported :: IO ()
test_glfwVulkanSupported =
    -- Just test that it doesn't error. If it does, then we have a problem, but
    -- some platforms (like OS X) don't actually support vulkan.
    c'glfwVulkanSupported >> return ()

test_glfwGetRequiredInstanceExtensions :: IO ()
test_glfwGetRequiredInstanceExtensions = do
    support <- c'glfwVulkanSupported
    if (support == 1)
        then alloca $ \p'count ->
            c'glfwGetRequiredInstanceExtensions p'count >> return ()
        else return ()

test_glfwGetInstanceProcAddress :: IO ()
test_glfwGetInstanceProcAddress = do
    return ()

test_glfwGetPhysicalDevicePresentationSupport :: IO ()
test_glfwGetPhysicalDevicePresentationSupport = do
    return ()

test_glfwCreateWindowSurface :: Ptr C'GLFWwindow -> IO ()
test_glfwCreateWindowSurface _ = do
    return ()

{-# ANN module "HLint: ignore Use camelCase" #-}
