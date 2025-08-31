# Event Management iOS App

A comprehensive iOS application for event management, built with SwiftUI and following modern iOS development practices.

## 🎉 Phase 2 Complete: Core User Interface

### ✅ **What's New in Phase 2:**

#### **Dashboard Views**
- **User Dashboard**: Personalized overview with upcoming events, group stats, and quick actions
- **Admin Dashboard**: System-wide statistics, user management, and administrative functions
- **Role-based Navigation**: Automatic switching between user and admin dashboards
- **Real-time Data**: Live updates with pull-to-refresh functionality

#### **Event Management**
- **Events List**: Comprehensive event browsing with search and filtering
- **Event Creation**: Full-featured event creation form with date/time pickers
- **Event Cards**: Rich event display with status indicators and details
- **Filtering Options**: All, Upcoming, Past, and My Events filters
- **Search Functionality**: Real-time search across event titles, descriptions, and locations

#### **Group Management**
- **Groups List**: Browse and manage groups with member statistics
- **Group Creation**: Create new groups with name and description
- **Join Groups**: Join existing groups using group codes
- **Group Cards**: Visual group representation with member counts and admin info
- **Filtering**: All, My Groups, and Available groups filters

#### **Enhanced UI/UX**
- **Material Design**: Consistent design system matching web client
- **Responsive Layout**: Optimized for all iOS devices
- **Loading States**: Proper loading indicators throughout the app
- **Error Handling**: Comprehensive error messages and recovery
- **Empty States**: Helpful empty state views with call-to-action buttons

## 🏗️ **Architecture**

### **MVVM Pattern**
- **Models**: Data structures for User, Event, Group, and API responses
- **ViewModels**: Business logic and state management for each view
- **Views**: SwiftUI views with declarative UI components

### **Key Components**

#### **Models**
- `User.swift`: User data model with computed properties
- `Event.swift`: Event data model with date formatting
- `Group.swift`: Group data model with member statistics
- API response models for all endpoints

#### **ViewModels**
- `DashboardViewModel`: User dashboard data management
- `AdminDashboardViewModel`: Admin dashboard data management
- `EventsViewModel`: Events list filtering and search
- `CreateEventViewModel`: Event creation form logic
- `GroupsViewModel`: Groups list filtering and search
- `CreateGroupViewModel`: Group creation form logic
- `JoinGroupViewModel`: Group joining logic

#### **Views**
- `DashboardView`: User dashboard with stats and quick actions
- `AdminDashboardView`: Admin dashboard with system overview
- `EventsView`: Events list with search and filtering
- `CreateEventView`: Event creation form
- `GroupsView`: Groups list with search and filtering
- `CreateGroupView`: Group creation form
- `JoinGroupView`: Group joining interface

#### **Components**
- `AppButton`: Reusable button with multiple styles
- `AppTextField`: Standardized text input fields
- `AppTextArea`: Multi-line text input
- `LoadingView`: Loading indicator
- `ErrorView`: Error display component

## 🎨 **Design System**

### **Colors**
- `appPrimary`: Primary brand color
- `appSecondary`: Secondary brand color
- `appBackground`: Background color
- `appSurface`: Card and surface colors
- `appTextPrimary/Secondary`: Text colors
- `grey50/100/600`: Neutral colors

### **Typography**
- `h1` through `h5`: Heading styles
- `body1/body2`: Body text styles
- `caption`: Small text styles

### **Spacing**
- `xs`, `sm`, `md`, `lg`, `xl`, `xxl`: Consistent spacing scale

### **Shadows & Corners**
- `AppShadows`: Small, medium, large shadow styles
- `AppCornerRadius`: Small, medium, large corner radius styles

## 🚀 **Features**

### **Authentication**
- ✅ User login and registration
- ✅ Admin account creation
- ✅ JWT token management
- ✅ Secure token storage with Keychain
- ✅ Automatic token refresh

### **Dashboard**
- ✅ Personalized user dashboard
- ✅ Admin dashboard with system stats
- ✅ Real-time data updates
- ✅ Quick action buttons
- ✅ Role-based navigation

### **Event Management**
- ✅ Browse all events
- ✅ Create new events
- ✅ Search and filter events
- ✅ Event status indicators
- ✅ Date and time pickers
- ✅ Location and capacity management

### **Group Management**
- ✅ Browse all groups
- ✅ Create new groups
- ✅ Join existing groups
- ✅ Group member statistics
- ✅ Admin information display

### **User Experience**
- ✅ Pull-to-refresh functionality
- ✅ Loading states
- ✅ Error handling
- ✅ Empty state views
- ✅ Form validation
- ✅ Cross-platform compatibility

## 📱 **Technical Stack**

- **Framework**: SwiftUI
- **Architecture**: MVVM (Model-View-ViewModel)
- **Networking**: URLSession with async/await
- **Storage**: Keychain for secure token storage
- **State Management**: @StateObject and @EnvironmentObject
- **Design**: Custom Material Design system

## 🔧 **Setup Instructions**

### **Prerequisites**
- Xcode 15.0+
- iOS 17.0+
- macOS 14.0+ (for development)

### **Installation**
1. Clone the repository
2. Open `event-management-ios.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run the project

### **Server Configuration**
- Ensure the Node.js server is running on `localhost:3000`
- Update `APIService.swift` if using a different server URL
- Configure `Info.plist` for network security if needed

## 🔐 **Security Features**

- **JWT Authentication**: Secure token-based authentication
- **Keychain Storage**: Secure token storage using iOS Keychain
- **HTTPS Support**: Ready for production HTTPS endpoints
- **Input Validation**: Client-side form validation
- **Error Handling**: Secure error message handling

## 📋 **API Integration**

### **Authentication Endpoints**
- `POST /auth/login` - User login
- `POST /auth/signup` - User registration
- `POST /auth/admin` - Admin account creation

### **Event Endpoints**
- `GET /events` - Get all events
- `POST /events` - Create new event
- `GET /events/:id` - Get event details
- `PUT /events/:id` - Update event
- `DELETE /events/:id` - Delete event

### **Group Endpoints**
- `GET /groups` - Get all groups
- `POST /groups` - Create new group
- `POST /groups/join` - Join group
- `GET /groups/:id` - Get group details

### **User Endpoints**
- `GET /users` - Get all users (admin only)
- `GET /users/me` - Get current user profile
- `PUT /users/me` - Update user profile

## 🎯 **Next Steps (Phase 3)**

### **Event Details & Management**
- Event detail views with full information
- Event editing and deletion
- Event attendance management
- Event sharing functionality

### **Group Details & Management**
- Group detail views with member lists
- Member management (add/remove)
- Group admin functions
- Group event management

### **Advanced Features**
- Push notifications
- Email integration
- Calendar integration
- Offline support
- Data synchronization

### **User Management**
- User profile editing
- Password change functionality
- User search and discovery
- Admin user management

### **Enhanced UI/UX**
- Dark mode support
- Accessibility improvements
- Animation and transitions
- Custom navigation patterns

## 🐛 **Known Issues**

- Group membership filtering needs backend support
- Event ownership filtering needs backend support
- Some placeholder navigation (TODO comments in code)

## 📞 **Support**

For questions or issues:
1. Check the API documentation
2. Review the server logs
3. Ensure proper network connectivity
4. Verify server endpoint availability

---

**Phase 2 Status**: ✅ **Complete**
**Next Phase**: Phase 3 - Advanced Features & Polish
