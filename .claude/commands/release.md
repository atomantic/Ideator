# Release to TestFlight

Build, archive, and upload to TestFlight locally.

## Instructions

1. **Pre-flight checks**:
   - Run `xcodebuild test -project Ideator.xcodeproj -scheme Ideator -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:IdeatorTests CODE_SIGNING_ALLOWED=NO -quiet` to ensure all tests pass
   - Run `git status` to ensure working tree is clean (no uncommitted changes)
   - If there are uncommitted changes, ask the user to commit first

2. **Run the deploy script**:
   - Execute `./deploy.sh` from the project root
   - This will: increment build number, run tests, archive, export IPA, and upload to TestFlight
   - If tests already passed in this session, the user may want `./deploy.sh --skip-tests`

3. **Monitor the upload**:
   - Watch for "UPLOAD SUCCEEDED" in the output
   - If you see "Checksums do not match" errors, the upload is retrying due to network issues — wait or suggest the user retry later
   - If you see "UPLOAD FAILED", check the error message for validation issues (missing Info.plist keys, etc.)

4. **Post-upload**:
   - The deploy script auto-commits the build number bump
   - Push the build number bump: `git push`
   - Inform the user the build should appear in TestFlight within 5-10 minutes

5. **If deploy.sh doesn't exist or .env is missing**:
   - Create `.env` from `.env.example`
   - The API key is at `~/Library/Mobile Documents/com~apple~CloudDocs/AppDev/AuthKey_DLJTLUDW5X.p8`
   - See the `ios-app-store-connect-setup` skill for full setup details
