# Analysis: User Profile Deep Linking

## Current State
- `NetworkScreen` opens profiles using `NetworkProfileView` via `MaterialPageRoute`.
- `AIAssistantWidget` currently mocks this by navigating to the *current user's* profile (`/student-profile`).
- We need to support viewing *other users'* profiles via the AI.

## Plan
1.  **Route Registration**: Register `/network-profile` in `main.dart`.
2.  **Argument Handling**: Configure `main.dart` to parse query parameters or arguments for `/network-profile`.
    - `NetworkProfileView` requires `userId` key. It also takes optional `userName`, `userAvatar`, `userRole`.
    - If I use query params, I can pass these as strings.
3.  **AI Logic Update**:
    - Update `_handleLocalRules` in `ai_assistant_widget.dart`.
    - When a profile is found (via `Supabase` search), construct a deep link:
      `/network-profile?id=${profile['id']}&name=${profile['full_name']}&role=${profile['role']}`.
4.  **Verification**: Test with "Who is [Name]".

## Nuances
- URL encoding for names with spaces.
- Handling missing fields (avatar).
