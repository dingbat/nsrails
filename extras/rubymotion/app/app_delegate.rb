class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)

    NSRConfig.defaultConfig.appURL = "http://nsrails.com"
    NSRConfig.defaultConfig.appUsername = "NSRails"
    NSRConfig.defaultConfig.appPassword = "iphone"

    posts = PostsViewController.alloc.initWithStyle(UITableViewStyleGrouped)
    nav = UINavigationController.alloc.initWithRootViewController(posts)

    @window.rootViewController = nav
    @window.makeKeyAndVisible

    true
  end
  
  def self.alertForError(e)
    errorString = ""

    #get the dictionary of validation errors, if present
    validationErrors = e.userInfo[NSRValidationErrorsKey]

    if (validationErrors)
      #iterate through each failed property (keys)
      validationErrors.each do |failed_property, reasons|
        #iterate through each reason the property failed
        reasons.each do |reason|
          errorString += "#{failed_property.capitalizedString} #{reason}. " #=> "Name can't be blank."
        end
      end
    else
      if (e.domain == NSRRemoteErrorDomain)
        errorString = "Something went wrong! Please try again later or contact us if this error continues."
      else
        errorString = "There was an error connecting to the server."
      end
    end

  	UIAlertView.alloc.initWithTitle("Error", message:errorString, delegate:nil, cancelButtonTitle:"OK", otherButtonTitles:nil).show
  end
end
