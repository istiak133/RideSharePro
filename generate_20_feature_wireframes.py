"""
RideShare AI Pro - Wireframe Generator for 20 Core MVP Features
Generates wireframe diagrams for Rider, Driver, and Admin screens
"""

from PIL import Image, ImageDraw, ImageFont
import os

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GRAY = (200, 200, 200)
DARK_GRAY = (100, 100, 100)
BLUE = (66, 133, 244)
GREEN = (52, 168, 83)
ORANGE = (251, 188, 5)
RED = (234, 67, 53)
LIGHT_BLUE = (219, 233, 252)
LIGHT_GREEN = (206, 237, 216)

# Screen dimensions (mobile)
SCREEN_WIDTH = 375
SCREEN_HEIGHT = 812
HEADER_HEIGHT = 80
BOTTOM_NAV_HEIGHT = 70

def create_phone_frame(draw):
    """Create phone screen frame"""
    draw.rectangle([0, 0, SCREEN_WIDTH, SCREEN_HEIGHT], fill=WHITE)
    draw.rectangle([0, 0, SCREEN_WIDTH, HEADER_HEIGHT], fill=BLUE)
    draw.rectangle([0, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT], fill=WHITE)
    draw.line([(0, HEADER_HEIGHT), (SCREEN_WIDTH, HEADER_HEIGHT)], fill=GRAY, width=2)
    draw.line([(0, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT), (SCREEN_WIDTH, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT)], fill=GRAY, width=2)

def add_text(draw, text, position, size=14, color=BLACK, bold=False):
    """Add text to image"""
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", size)
    except:
        font = ImageFont.load_default()
    draw.text(position, text, fill=color, font=font)

def add_button(draw, position, size, text, bg_color=BLUE, text_color=WHITE):
    """Add button"""
    x, y = position
    w, h = size
    draw.rectangle([x, y, x + w, y + h], fill=bg_color)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 16)
    except:
        font = ImageFont.load_default()
    text_width = draw.textlength(text, font=font)
    draw.text((x + (w - text_width) / 2, y + (h - 20) / 2), text, fill=text_color, font=font)

def add_input_field(draw, position, size, placeholder):
    """Add input field"""
    x, y = position
    w, h = size
    draw.rectangle([x, y, x + w, y + h], fill=WHITE, outline=GRAY)
    add_text(draw, placeholder, (x + 15, y + 15), size=14, color=DARK_GRAY)

def add_icon_placeholder(draw, position, size, label):
    """Add icon placeholder"""
    x, y = position
    w, h = size
    draw.ellipse([x, y, x + w, y + h], fill=LIGHT_BLUE, outline=BLUE)
    add_text(draw, label, (x + 5, y + h/2 - 8), size=10, color=BLUE)

def create_wireframe_screen(title, draw_func):
    """Create a complete wireframe screen"""
    img = Image.new('RGB', (SCREEN_WIDTH, SCREEN_HEIGHT), WHITE)
    draw = ImageDraw.Draw(img)
    create_phone_frame(draw)
    add_text(draw, title, (20, 25), size=20, color=WHITE)
    draw_func(draw)
    return img

# ==================== RIDER SCREENS ====================

def screen_phone_login(draw):
    """Feature 1: Phone Login"""
    add_text(draw, "Enter Your Phone Number", (20, 110), size=24, color=BLACK)
    add_text(draw, "We'll send you a 6-digit OTP code", (20, 145), size=14, color=DARK_GRAY)
    
    # Country code + phone input
    draw.rectangle([20, 180, 80, 230], fill=WHITE, outline=GRAY)
    add_text(draw, "+880", (30, 195), size=16)
    
    draw.rectangle([90, 180, 355, 230], fill=WHITE, outline=GRAY)
    add_text(draw, "1XXXXXXXXX", (105, 195), size=16, color=DARK_GRAY)
    
    add_button(draw, (20, 260), (335, 55), "Send OTP")
    
    # Info text
    add_text(draw, "✓ No password required", (20, 340), size=13, color=GREEN)
    add_text(draw, "✓ Secure OTP verification", (20, 365), size=13, color=GREEN)
    add_text(draw, "✓ Takes less than 30 seconds", (20, 390), size=13, color=GREEN)

def screen_otp_verify(draw):
    """Feature 1: OTP Verification"""
    add_text(draw, "Enter OTP Code", (20, 110), size=24, color=BLACK)
    add_text(draw, "Code sent to +880 1XXXXXXXXX", (20, 145), size=14, color=DARK_GRAY)
    
    # OTP input boxes
    for i in range(6):
        x = 40 + i * 50
        draw.rectangle([x, 190, x + 40, 230], fill=WHITE, outline=BLUE, width=2)
    
    # Resend OTP
    add_text(draw, "Didn't receive code?", (100, 260), size=14, color=DARK_GRAY)
    add_text(draw, "Resend OTP", (250, 260), size=14, color=BLUE)
    
    # Timer
    add_text(draw, "Resend available in 0:30", (100, 285), size=13, color=ORANGE)
    
    add_button(draw, (20, 330), (335, 55), "Verify & Continue")

def screen_profile_setup(draw):
    """Feature 2: Profile Setup"""
    add_text(draw, "Complete Your Profile", (20, 110), size=24, color=BLACK)
    
    # Profile photo upload
    draw.ellipse([147, 150, 227, 230], fill=LIGHT_BLUE, outline=BLUE, width=2)
    add_text(draw, "📷", (177, 180), size=30)
    add_text(draw, "Tap to add photo", (120, 240), size=13, color=BLUE)
    
    # Input fields
    add_input_field(draw, (20, 280), (335, 50), "Full Name *")
    add_input_field(draw, (20, 340), (335, 50), "Date of Birth *")
    add_input_field(draw, (20, 400), (335, 50), "Email (optional)")
    add_input_field(draw, (20, 460), (335, 50), "Emergency Contact Name")
    add_input_field(draw, (20, 520), (335, 50), "Emergency Contact Phone")
    
    add_button(draw, (20, 590), (335, 55), "Save Profile")

def screen_home_map(draw):
    """Feature 5: Home Map"""
    # Map area
    draw.rectangle([0, HEADER_HEIGHT, SCREEN_WIDTH, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT], fill=LIGHT_BLUE)
    add_text(draw, "[ GOOGLE MAP ]", (100, 250), size=18, color=BLUE)
    
    # Current location button
    draw.rectangle([310, 350, 355, 395], fill=WHITE)
    add_text(draw, "📍", (320, 358), size=24)
    
    # Where to? search box
    draw.rectangle([20, 120, 355, 170], fill=WHITE)
    add_text(draw, "🔍 Where to?", (40, 135), size=16)
    
    # Current location indicator
    draw.ellipse([175, 275, 205, 305], fill=BLUE)
    draw.ellipse([185, 285, 195, 295], fill=WHITE)

def screen_select_location(draw):
    """Feature 5: Select Pickup/Destination"""
    # Map area
    draw.rectangle([0, HEADER_HEIGHT, SCREEN_WIDTH, 350], fill=LIGHT_BLUE)
    add_text(draw, "[ MAP WITH ROUTE ]", (90, 200), size=18, color=BLUE)
    
    # Pickup
    draw.rectangle([0, 350, SCREEN_WIDTH, 420], fill=WHITE)
    add_icon_placeholder(draw, (20, 370), (30, 30), "A")
    add_text(draw, "Pickup Location", (65, 375), size=16)
    add_text(draw, "Current Location", (65, 400), size=13, color=DARK_GRAY)
    
    # Destination
    draw.rectangle([0, 420, SCREEN_WIDTH, 490], fill=WHITE)
    add_icon_placeholder(draw, (20, 440), (30, 30), "B")
    add_text(draw, "Destination", (65, 445), size=16)
    add_text(draw, "Search for destination...", (65, 470), size=13, color=DARK_GRAY)
    
    add_button(draw, (20, 520), (335, 55), "Confirm Locations")

def screen_fare_estimate(draw):
    """Feature 6: Fare Estimate"""
    add_text(draw, "Fare Estimate", (20, 110), size=24, color=BLACK)
    
    # Route info
    draw.rectangle([20, 130, 355, 200], fill=LIGHT_BLUE)
    add_text(draw, "📍 Pickup → Destination", (35, 145), size=16)
    add_text(draw, "Distance: 12.5 km", (35, 170), size=14, color=DARK_GRAY)
    add_text(draw, "ETA: 25 min", (35, 190), size=14, color=DARK_GRAY)
    
    # Fare breakdown
    draw.rectangle([20, 220, 355, 380], fill=WHITE, outline=GRAY)
    add_text(draw, "Fare Breakdown:", (35, 235), size=16, bold=True)
    add_text(draw, "Base Fare: ৳80", (35, 265), size=14)
    add_text(draw, "Distance (12.5 km × ৳30): ৳375", (35, 290), size=14)
    add_text(draw, "Time (25 min × ৳2): ৳50", (35, 315), size=14)
    draw.line([(35, 335), (340, 335)], fill=GRAY, width=1)
    add_text(draw, "Total Estimated Fare: ৳505", (35, 350), size=18, color=BLUE, bold=True)
    
    add_button(draw, (20, 410), (335, 55), "Confirm Booking")

def screen_searching_driver(draw):
    """Feature 7 & 9: Searching for Driver"""
    add_text(draw, "Finding Your Driver", (20, 110), size=24, color=BLACK)
    
    # Animation placeholder
    draw.ellipse([137, 180, 237, 280], fill=LIGHT_BLUE, outline=BLUE)
    add_text(draw, "🔄", (167, 215), size=40)
    
    add_text(draw, "Searching for nearby drivers...", (60, 310), size=16, color=DARK_GRAY)
    
    # Progress indicator
    draw.rectangle([20, 350, 355, 370], fill=GRAY)
    draw.rectangle([20, 350, 150, 370], fill=BLUE)
    
    add_text(draw, "Estimated wait: 2-3 minutes", (80, 390), size=14, color=DARK_GRAY)
    
    # Cancel button
    add_button(draw, (20, 430), (335, 55), "Cancel Request", bg_color=RED)

def screen_driver_found(draw):
    """Feature 10: Driver Found"""
    add_text(draw, "Driver Found!", (20, 110), size=24, color=GREEN)
    
    # Driver info card
    draw.rectangle([20, 140, 355, 300], fill=WHITE, outline=GREEN)
    draw.ellipse([40, 160, 100, 220], fill=LIGHT_GREEN)
    add_text(draw, "👤", (55, 175), size=30)
    
    add_text(draw, "Driver: Ahmed Rahman", (115, 165), size=18, bold=True)
    add_text(draw, "Rating: ⭐ 4.8 (234 rides)", (115, 190), size=14)
    add_text(draw, "Car: Toyota Prius | White", (115, 215), size=14)
    add_text(draw, "Plate: DHAKA-GA-12-3456", (115, 240), size=14)
    add_text(draw, "ETA: 5 minutes", (115, 265), size=16, color=BLUE, bold=True)
    
    # OTP Code
    draw.rectangle([20, 320, 355, 380], fill=LIGHT_BLUE)
    add_text(draw, "Your Pickup OTP:", (120, 335), size=16)
    add_text(draw, "7 5 2 9", (130, 355), size=36, color=BLUE, bold=True)
    
    add_button(draw, (20, 410), (335, 55), "Track Driver")

def screen_live_tracking(draw):
    """Feature 11: Live Tracking"""
    # Map area
    draw.rectangle([0, HEADER_HEIGHT, SCREEN_WIDTH, 450], fill=LIGHT_BLUE)
    add_text(draw, "[ LIVE MAP ]", (120, 250), size=18, color=BLUE)
    
    # Driver car icon
    add_icon_placeholder(draw, (170, 230), (40, 40), "🚗")
    
    # Info panel
    draw.rectangle([0, 450, SCREEN_WIDTH, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT], fill=WHITE)
    add_text(draw, "Driver Arriving", (20, 470), size=20, bold=True)
    add_text(draw, "ETA: 3 min (1.2 km)", (20, 500), size=16, color=BLUE)
    
    # Progress bar
    draw.rectangle([20, 530, 355, 545], fill=GRAY)
    draw.rectangle([20, 530, 250, 545], fill=GREEN)
    
    add_text(draw, "Route: Highway → Main Road → Your Location", (20, 565), size=13, color=DARK_GRAY)
    
    # Chat button
    draw.rectangle([280, 470, 355, 520], fill=BLUE)
    add_text(draw, "💬", (300, 485), size=28)

def screen_eta_updates(draw):
    """Feature 12: ETA Updates"""
    add_text(draw, "On The Way", (20, 110), size=24, color=BLACK)
    
    # ETA card
    draw.rectangle([20, 140, 355, 220], fill=LIGHT_GREEN)
    add_text(draw, "Estimated Arrival", (35, 155), size=16)
    add_text(draw, "12 min", (35, 180), size=42, color=GREEN, bold=True)
    add_text(draw, "8.5 km remaining", (35, 235), size=14, color=DARK_GRAY)
    
    # Route progress
    add_text(draw, "Route Progress:", (20, 280), size=16, bold=True)
    waypoints = ["✓ Highway", "→ Main Road", "○ Destination Street"]
    for i, waypoint in enumerate(waypoints):
        color = GREEN if i == 0 else BLUE if i == 1 else DARK_GRAY
        add_text(draw, waypoint, (35, 310 + i*30), size=14, color=color)
    
    # Live fare estimate
    draw.rectangle([20, 430, 355, 480], fill=LIGHT_BLUE)
    add_text(draw, "Current Fare Estimate: ৳505", (35, 450), size=16, color=BLUE)

def screen_ride_progress(draw):
    """Feature 14: Ride in Progress"""
    # Map area
    draw.rectangle([0, HEADER_HEIGHT, SCREEN_WIDTH, 400], fill=LIGHT_BLUE)
    add_text(draw, "[ RIDE MAP ]", (120, 230), size=18, color=BLUE)
    
    # Status bar
    draw.rectangle([0, 400, SCREEN_WIDTH, 450], fill=GREEN)
    add_text(draw, "Ride in Progress", (20, 415), size=20, color=WHITE)
    
    # Info panel
    draw.rectangle([0, 450, SCREEN_WIDTH, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT], fill=WHITE)
    add_text(draw, "Destination: Gulshan-1", (20, 470), size=18, bold=True)
    add_text(draw, "Distance: 6.2 km remaining", (20, 500), size=15)
    add_text(draw, "ETA: 10 minutes", (20, 525), size=15, color=BLUE)
    add_text(draw, "Fare: ৳505", (20, 550), size=15)
    
    # Share ride button
    add_button(draw, (20, 590), (335, 50), "Share Ride Status", bg_color=BLUE)

def screen_in_app_chat(draw):
    """Feature 15: In-App Chat"""
    add_text(draw, "Chat with Driver", (20, 110), size=20, color=BLACK)
    
    # Chat messages
    # Driver message
    draw.rectangle([20, 150, 250, 200], fill=GRAY)
    add_text(draw, "I'm 2 minutes away", (30, 165), size=14)
    add_text(draw, "2:30 PM", (30, 185), size=11, color=DARK_GRAY)
    
    # Rider message
    draw.rectangle([125, 220, 355, 270], fill=LIGHT_BLUE)
    add_text(draw, "Great! I'm at the main gate", (135, 235), size=14)
    add_text(draw, "2:31 PM ✓✓", (240, 255), size=11, color=BLUE)
    
    # Driver message
    draw.rectangle([20, 290, 280, 340], fill=GRAY)
    add_text(draw, "Perfect, see you in a moment!", (30, 305), size=14)
    add_text(draw, "2:32 PM", (30, 325), size=11, color=DARK_GRAY)
    
    # Message input
    draw.rectangle([20, 650, 280, 700], fill=WHITE, outline=GRAY)
    add_text(draw, "Type a message...", (35, 665), size=14, color=DARK_GRAY)
    add_button(draw, (300, 650), (55, 50), "➤", bg_color=BLUE)
    
    add_text(draw, "Chat will be deleted after 24 hours", (60, 715), size=11, color=DARK_GRAY)

def screen_payment(draw):
    """Feature 17: Payment"""
    add_text(draw, "Payment", (20, 110), size=24, color=BLACK)
    
    # Ride summary
    draw.rectangle([20, 140, 355, 220], fill=LIGHT_BLUE)
    add_text(draw, "Ride Summary", (35, 155), size=16, bold=True)
    add_text(draw, "Distance: 12.5 km", (35, 180), size=14)
    add_text(draw, "Duration: 28 min", (35, 205), size=14)
    
    # Payment methods
    add_text(draw, "Select Payment Method:", (20, 250), size=16, bold=True)
    
    # Cash option
    draw.rectangle([20, 280, 355, 330], fill=WHITE, outline=GREEN, width=2)
    add_text(draw, "💵 Cash", (35, 295), size=18, bold=True)
    add_text(draw, "Pay directly to driver", (35, 318), size=13, color=DARK_GRAY)
    
    # Card option
    draw.rectangle([20, 345, 355, 395], fill=WHITE, outline=GRAY)
    add_text(draw, "💳 Card (•••• 4242)", (35, 360), size=18)
    add_text(draw, "Visa", (35, 383), size=13, color=DARK_GRAY)
    
    # Total amount
    draw.rectangle([20, 420, 355, 480], fill=LIGHT_GREEN)
    add_text(draw, "Total Amount", (35, 435), size=16)
    add_text(draw, "৳505", (35, 455), size=36, color=GREEN, bold=True)
    
    add_button(draw, (20, 510), (335, 55), "Confirm Payment")

def screen_rate_driver(draw):
    """Feature not in list but part of ride completion"""
    add_text(draw, "Rate Your Driver", (20, 110), size=24, color=BLACK)
    
    # Driver info
    draw.ellipse([147, 150, 227, 230], fill=LIGHT_GREEN)
    add_text(draw, "👤", (167, 175), size=30)
    add_text(draw, "Ahmed Rahman", (125, 245), size=18, bold=True)
    
    # Star rating
    add_text(draw, "Tap to rate:", (120, 280), size=16)
    stars = "⭐ ⭐ ⭐ ⭐ ⭐"
    add_text(draw, stars, (75, 310), size=32)
    
    # Comment
    add_input_field(draw, (20, 370), (335, 100), "Add a comment (optional)")
    
    add_button(draw, (20, 490), (335, 55), "Submit Rating")
    
    # Skip option
    add_text(draw, "Skip", (165, 565), size=16, color=DARK_GRAY)

# ==================== DRIVER SCREENS ====================

def screen_driver_login(draw):
    """Feature 1: Driver Login"""
    add_text(draw, "Driver Login", (20, 110), size=24, color=BLACK)
    add_text(draw, "Enter your phone number", (20, 145), size=14, color=DARK_GRAY)
    
    # Phone input
    draw.rectangle([90, 180, 355, 230], fill=WHITE, outline=GRAY)
    add_text(draw, "1XXXXXXXXX", (105, 195), size=16, color=DARK_GRAY)
    
    add_button(draw, (20, 260), (335, 55), "Send OTP")
    
    # Toggle role
    draw.rectangle([20, 330, 355, 380], fill=LIGHT_BLUE)
    add_text(draw, "Switch to Rider Account", (100, 345), size=16, color=BLUE)

def screen_upload_documents(draw):
    """Feature 3: Upload Documents"""
    add_text(draw, "Upload Documents", (20, 110), size=24, color=BLACK)
    add_text(draw, "All fields are required", (20, 140), size=13, color=DARK_GRAY)
    
    # Document upload boxes
    docs = [
        ("NID Card - Front", 160),
        ("NID Card - Back", 220),
        ("Driving License", 280),
        ("Vehicle Photo", 340),
        ("Vehicle Registration", 400)
    ]
    
    for label, y_pos in docs:
        draw.rectangle([20, y_pos, 355, y_pos + 50], fill=WHITE, outline=GRAY)
        add_text(draw, f"📄 {label}", (35, y_pos + 15), size=15)
        add_text(draw, "Tap to upload", (200, y_pos + 15), size=13, color=BLUE)
    
    # Bank details
    add_text(draw, "Bank Account Details:", (20, 470), size=16, bold=True)
    add_input_field(draw, (20, 495), (335, 40), "Account Number")
    add_input_field(draw, (20, 540), (335, 40), "Bank Name")
    
    add_button(draw, (20, 600), (335, 55), "Submit for Verification")

def screen_pending_verification(draw):
    """Feature 4: Pending Verification"""
    # Waiting icon
    draw.ellipse([137, 150, 237, 250], fill=ORANGE)
    add_text(draw, "⏳", (167, 185), size=40)
    
    add_text(draw, "Under Review", (110, 280), size=28, color=ORANGE, bold=True)
    add_text(draw, "Your documents are being verified", (50, 320), size=16, color=DARK_GRAY)
    
    # Info card
    draw.rectangle([20, 370, 355, 480], fill=LIGHT_BLUE)
    add_text(draw, "Estimated Time:", (35, 390), size=16)
    add_text(draw, "Usually verified within 24 hours", (35, 415), size=14)
    add_text(draw, "You'll receive a notification once verified", (35, 440), size=14)
    add_text(draw, "Contact support if it takes longer", (35, 465), size=14)
    
    add_text(draw, "You cannot accept rides until verified", (60, 520), size=13, color=RED)

def screen_go_online(draw):
    """Feature 16: Go Online/Offline"""
    add_text(draw, "Driver Dashboard", (20, 110), size=24, color=BLACK)
    
    # Status indicator
    draw.rectangle([20, 150, 355, 200], fill=LIGHT_GREEN)
    add_text(draw, "Status: ONLINE", (35, 165), size=20, color=GREEN, bold=True)
    add_text(draw, "You're receiving ride requests", (35, 188), size=14)
    
    # Toggle button
    draw.rectangle([137, 250, 237, 310], fill=GREEN)
    add_text(draw, "ONLINE", (150, 270), size=18, color=WHITE, bold=True)
    add_text(draw, "Tap to go offline", (120, 325), size=13, color=DARK_GRAY)
    
    # Today's stats
    add_text(draw, "Today's Summary:", (20, 370), size=18, bold=True)
    stats = [
        ("Trips Completed:", "5"),
        ("Earnings:", "৳1,875"),
        ("Online Time:", "4h 32m")
    ]
    for i, (label, value) in enumerate(stats):
        y = 400 + i * 40
        add_text(draw, label, (35, y), size=15)
        add_text(draw, value, (250, y), size=15, color=GREEN, bold=True)

def screen_ride_request(draw):
    """Feature 10: Ride Request"""
    add_text(draw, "NEW RIDE REQUEST", (80, 110), size=20, color=BLUE, bold=True)
    
    # Countdown timer
    draw.rectangle([20, 150, 355, 200], fill=LIGHT_BLUE)
    add_text(draw, "Accept within:", (35, 165), size=16)
    add_text(draw, "0:25", (280, 160), size=36, color=BLUE, bold=True)
    
    # Ride details
    draw.rectangle([20, 220, 355, 380], fill=WHITE, outline=GRAY)
    add_text(draw, "Pickup: Banani Road 11", (35, 240), size=16, bold=True)
    add_text(draw, "Drop: Gulshan-1, Circle", (35, 270), size=16)
    add_text(draw, "Distance: 3.2 km", (35, 310), size=14, color=DARK_GRAY)
    add_text(draw, "Estimated Fare: ৳245", (35, 335), size=18, color=GREEN, bold=True)
    add_text(draw, "Rider Rating: ⭐ 4.7", (35, 360), size=14)
    
    # Accept/Decline buttons
    add_button(draw, (20, 410), (160, 60), "ACCEPT", bg_color=GREEN)
    add_button(draw, (195, 410), (160, 60), "DECLINE", bg_color=RED)

def screen_navigate_to_pickup(draw):
    """Feature 10 & 14: Navigate to Pickup"""
    # Navigation map
    draw.rectangle([0, HEADER_HEIGHT, SCREEN_WIDTH, 500], fill=LIGHT_BLUE)
    add_text(draw, "[ NAVIGATION MAP ]", (90, 300), size=18, color=BLUE)
    
    # Navigation info
    draw.rectangle([0, 500, SCREEN_WIDTH, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT], fill=WHITE)
    add_text(draw, "Navigate to Pickup", (20, 520), size=20, bold=True)
    add_text(draw, "Distance: 1.5 km", (20, 555), size=16)
    add_text(draw, "ETA: 4 minutes", (20, 580), size=16, color=BLUE)
    
    # I've Arrived button
    add_button(draw, (20, 620), (335, 55), "I've Arrived", bg_color=GREEN)
    
    add_text(draw, "Button activates when you're 50m away", (50, 685), size=12, color=DARK_GRAY)

def screen_enter_otp(draw):
    """Feature 13: Enter OTP"""
    add_text(draw, "Enter Pickup OTP", (20, 110), size=24, color=BLACK)
    add_text(draw, "Ask the rider for their 4-digit code", (20, 145), size=14, color=DARK_GRAY)
    
    # OTP input boxes
    for i in range(4):
        x = 80 + i * 60
        draw.rectangle([x, 200, x + 50, 260], fill=WHITE, outline=BLUE, width=2)
    
    # Info
    draw.rectangle([20, 300, 355, 360], fill=LIGHT_BLUE)
    add_text(draw, "This verifies you picked up the", (35, 315), size=14)
    add_text(draw, "correct rider", (35, 335), size=14)
    
    # Attempts
    add_text(draw, "Attempts remaining: 3", (100, 390), size=14, color=ORANGE)
    
    add_button(draw, (20, 430), (335, 55), "Verify OTP")
    
    # Start Ride button (disabled)
    draw.rectangle([20, 510, 355, 565], fill=GRAY)
    add_text(draw, "Start Ride (After OTP Verified)", (60, 530), size=16, color=WHITE)

def screen_ride_active(draw):
    """Feature 14: Active Ride"""
    # Navigation map
    draw.rectangle([0, HEADER_HEIGHT, SCREEN_WIDTH, 450], fill=LIGHT_GREEN)
    add_text(draw, "[ NAVIGATION TO DEST ]", (80, 250), size=18, color=GREEN)
    
    # Ride status
    draw.rectangle([0, 450, SCREEN_WIDTH, 500], fill=GREEN)
    add_text(draw, "RIDE IN PROGRESS", (90, 465), size=20, color=WHITE, bold=True)
    
    # Info panel
    draw.rectangle([0, 500, SCREEN_WIDTH, SCREEN_HEIGHT - BOTTOM_NAV_HEIGHT], fill=WHITE)
    add_text(draw, "Destination: Gulshan-1", (20, 520), size=18, bold=True)
    add_text(draw, "Distance: 8.2 km", (20, 555), size=16)
    add_text(draw, "ETA: 15 minutes", (20, 580), size=16, color=BLUE)
    add_text(draw, "Current Fare: ৳385", (20, 605), size=16)
    
    # End Ride button
    add_button(draw, (20, 650), (335, 55), "End Ride", bg_color=RED)

def screen_end_ride(draw):
    """Feature 14: End Ride Summary"""
    add_text(draw, "Ride Completed!", (20, 110), size=24, color=GREEN, bold=True)
    
    # Summary card
    draw.rectangle([20, 140, 355, 360], fill=WHITE, outline=GREEN)
    add_text(draw, "Ride Summary", (35, 160), size=18, bold=True)
    
    details = [
        ("Distance:", "12.5 km"),
        ("Duration:", "28 min"),
        ("Base Fare:", "৳80"),
        ("Distance Fare:", "৳375"),
        ("Time Fare:", "৳50"),
    ]
    
    for i, (label, value) in enumerate(details):
        y = 195 + i * 30
        add_text(draw, label, (35, y), size=15)
        add_text(draw, value, (250, y), size=15)
    
    draw.line([(35, 345), (340, 345)], fill=GRAY, width=2)
    add_text(draw, "Total:", (35, 355), size=18, bold=True)
    add_text(draw, "৳505", (250, 355), size=18, color=GREEN, bold=True)
    
    add_button(draw, (20, 390), (335, 55), "Confirm Payment Received")

# ==================== ADMIN SCREENS ====================

def screen_admin_dashboard(draw):
    """Feature 19: Admin Dashboard"""
    add_text(draw, "Admin Dashboard", (20, 110), size=24, color=BLACK)
    
    # Stats cards
    stats = [
        ("Today's Rides", "156", BLUE, 160),
        ("Revenue", "৳45,230", GREEN, 230),
        ("Active Drivers", "42", ORANGE, 300),
        ("Pending Verifications", "8", RED, 370)
    ]
    
    for label, value, color, y_pos in stats:
        draw.rectangle([20, y_pos, 355, y_pos + 55], fill=color)
        add_text(draw, label, (35, y_pos + 10), size=14, color=WHITE)
        add_text(draw, value, (35, y_pos + 30), size=22, color=WHITE, bold=True)
    
    # Charts placeholder
    draw.rectangle([20, 450, 355, 550], fill=LIGHT_BLUE)
    add_text(draw, "[ 7-Day Rides Chart ]", (110, 490), size=16, color=BLUE)
    
    draw.rectangle([20, 570, 355, 650], fill=LIGHT_GREEN)
    add_text(draw, "[ Revenue Breakdown ]", (110, 600), size=16, color=GREEN)

def screen_verify_driver(draw):
    """Feature 4: Verify Driver (Admin)"""
    add_text(draw, "Driver Verification", (20, 110), size=24, color=BLACK)
    
    # Driver info
    draw.rectangle([20, 140, 355, 220], fill=LIGHT_BLUE)
    draw.ellipse([35, 150, 85, 200], fill=WHITE)
    add_text(draw, "👤", (45, 160), size=28)
    add_text(draw, "Rahim Ahmed", (100, 155), size=18, bold=True)
    add_text(draw, "📞 +880 1712345678", (100, 180), size=14)
    add_text(draw, "Submitted: 2 hours ago", (100, 200), size=13, color=DARK_GRAY)
    
    # Documents
    add_text(draw, "Documents:", (20, 250), size=16, bold=True)
    docs = ["NID Front ✓", "NID Back ✓", "License ✓", "Vehicle Photo ✓"]
    for i, doc in enumerate(docs):
        y = 275 + i * 30
        color = GREEN if "✓" in doc else ORANGE
        add_text(draw, f"📄 {doc}", (35, y), size=14, color=color)
    
    # Vehicle info
    draw.rectangle([20, 400, 355, 460], fill=WHITE, outline=GRAY)
    add_text(draw, "Vehicle: Toyota Prius 2020", (35, 415), size=15)
    add_text(draw, "Plate: DHAKA-GA-12-3456", (35, 440), size=15)
    
    # Action buttons
    add_button(draw, (20, 490), (160, 55), "APPROVE", bg_color=GREEN)
    add_button(draw, (195, 490), (160, 55), "REJECT", bg_color=RED)
    
    # Rejection reason
    add_input_field(draw, (20, 560), (335, 50), "Rejection reason (if rejected)")

def screen_user_management(draw):
    """Feature 20: User Management"""
    add_text(draw, "User Management", (20, 110), size=24, color=BLACK)
    
    # Search bar
    draw.rectangle([20, 140, 355, 185], fill=WHITE, outline=GRAY)
    add_text(draw, "🔍 Search by name, phone, or ID...", (35, 152), size=15, color=DARK_GRAY)
    
    # Filter tabs
    draw.rectangle([20, 200, 120, 235], fill=BLUE)
    add_text(draw, "All", (65, 208), size=14, color=WHITE)
    draw.rectangle([130, 200, 230, 235], fill=WHITE, outline=GRAY)
    add_text(draw, "Riders", (160, 208), size=14)
    draw.rectangle([240, 200, 340, 235], fill=WHITE, outline=GRAY)
    add_text(draw, "Drivers", (265, 208), size=14)
    
    # User list
    users = [
        ("Ahmed Rahman", "Rider", "⭐ 4.8", "Active", GREEN),
        ("Karim Hassan", "Driver", "⭐ 4.9", "Online", GREEN),
        ("Fatima Ali", "Rider", "⭐ 3.2", "Blocked", RED),
        ("Rashid Khan", "Driver", "⭐ 4.5", "Offline", GRAY),
        ("Nasreen Akter", "Rider", "⭐ 4.7", "Active", GREEN),
    ]
    
    for i, (name, role, rating, status, status_color) in enumerate(users):
        y = 255 + i * 70
        draw.rectangle([20, y, 355, y + 60], fill=WHITE, outline=GRAY)
        draw.ellipse([30, y + 10, 60, y + 40], fill=LIGHT_BLUE)
        add_text(draw, name, (75, y + 12), size=16, bold=True)
        add_text(draw, f"{role} | {rating}", (75, y + 35), size=13, color=DARK_GRAY)
        draw.rectangle([250, y + 15, 345, y + 40], fill=status_color)
        add_text(draw, status, (270, y + 18), size=13, color=WHITE)

def screen_notifications(draw):
    """Feature 18: Push Notifications"""
    add_text(draw, "Notifications", (20, 110), size=24, color=BLACK)
    
    # Notification list
    notifications = [
        ("Ride Accepted", "Ahmed Rahman accepted your ride", "2 min ago", BLUE),
        ("Driver Arriving", "Your driver is 3 minutes away", "10 min ago", GREEN),
        ("Ride Completed", "Thank you for riding with us!", "1 hour ago", GRAY),
        ("Payment Confirmed", "৳505 payment successful", "1 hour ago", GREEN),
        ("Rate Your Driver", "How was your experience?", "2 hours ago", ORANGE),
    ]
    
    for i, (title, message, time, color) in enumerate(notifications):
        y = 140 + i * 90
        draw.rectangle([20, y, 355, y + 80], fill=WHITE, outline=GRAY)
        draw.rectangle([35, y + 15, 45, y + 25], fill=color)
        add_text(draw, title, (55, y + 12), size=16, bold=True)
        add_text(draw, message, (55, y + 35), size=13, color=DARK_GRAY)
        add_text(draw, time, (55, y + 60), size=12, color=GRAY)

def screen_schedule_ride(draw):
    """Feature 8: Schedule a Ride"""
    add_text(draw, "Schedule a Ride", (20, 110), size=24, color=BLACK)
    
    # Date picker
    draw.rectangle([20, 150, 355, 200], fill=WHITE, outline=GRAY)
    add_text(draw, "📅 Select Date", (35, 165), size=16)
    add_text(draw, "Tomorrow, April 29", (35, 188), size=14, color=BLUE)
    
    # Time picker
    draw.rectangle([20, 220, 355, 270], fill=WHITE, outline=GRAY)
    add_text(draw, "🕐 Select Time", (35, 235), size=16)
    add_text(draw, "08:30 AM", (35, 258), size=14, color=BLUE)
    
    # Info
    draw.rectangle([20, 290, 355, 350], fill=LIGHT_BLUE)
    add_text(draw, "ℹ️ Scheduling Rules:", (35, 305), size=14, bold=True)
    add_text(draw, "• Minimum 1 hour in advance", (35, 325), size=13)
    add_text(draw, "• Maximum 7 days in advance", (35, 342), size=13)
    
    # Location (same as booking)
    add_text(draw, "Locations:", (20, 380), size=16, bold=True)
    add_input_field(draw, (20, 400), (335, 45), "Pickup Location")
    add_input_field(draw, (20, 450), (335, 45), "Destination")
    
    add_button(draw, (20, 520), (335, 55), "Schedule Ride")


# ==================== GENERATE ALL SCREENS ====================

def generate_wireframes():
    """Generate all wireframe screens"""
    output_dir = "/Users/istiakahmed/RideSharePro/wireframes_20_features"
    os.makedirs(output_dir, exist_ok=True)
    
    # Rider screens
    rider_screens = [
        ("01_rider_phone_login.png", screen_phone_login),
        ("02_rider_otp_verify.png", screen_otp_verify),
        ("03_rider_profile_setup.png", screen_profile_setup),
        ("04_rider_home_map.png", screen_home_map),
        ("05_rider_select_location.png", screen_select_location),
        ("06_rider_fare_estimate.png", screen_fare_estimate),
        ("07_rider_searching_driver.png", screen_searching_driver),
        ("08_rider_driver_found.png", screen_driver_found),
        ("09_rider_live_tracking.png", screen_live_tracking),
        ("10_rider_eta_updates.png", screen_eta_updates),
        ("11_rider_ride_progress.png", screen_ride_progress),
        ("12_rider_in_app_chat.png", screen_in_app_chat),
        ("13_rider_payment.png", screen_payment),
        ("14_rider_schedule_ride.png", screen_schedule_ride),
    ]
    
    # Driver screens
    driver_screens = [
        ("15_driver_login.png", screen_driver_login),
        ("16_driver_upload_docs.png", screen_upload_documents),
        ("17_driver_pending_verification.png", screen_pending_verification),
        ("18_driver_go_online.png", screen_go_online),
        ("19_driver_ride_request.png", screen_ride_request),
        ("20_driver_navigate_pickup.png", screen_navigate_to_pickup),
        ("21_driver_enter_otp.png", screen_enter_otp),
        ("22_driver_ride_active.png", screen_ride_active),
        ("23_driver_end_ride.png", screen_end_ride),
    ]
    
    # Admin screens
    admin_screens = [
        ("24_admin_dashboard.png", screen_admin_dashboard),
        ("25_admin_verify_driver.png", screen_verify_driver),
        ("26_admin_user_management.png", screen_user_management),
    ]
    
    all_screens = [
        ("rider", rider_screens),
        ("driver", driver_screens),
        ("admin", admin_screens),
    ]
    
    for category, screens in all_screens:
        for filename, draw_func in screens:
            filepath = os.path.join(output_dir, filename)
            title = filename.replace('.png', '').replace('_', ' ').title()
            img = create_wireframe_screen(title, draw_func)
            img.save(filepath)
            print(f"✓ Generated: {filename}")
    
    print(f"\n🎉 All wireframes saved to: {output_dir}")

if __name__ == "__main__":
    generate_wireframes()
