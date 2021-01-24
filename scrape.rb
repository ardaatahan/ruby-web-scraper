require "selenium-webdriver"
require "Nokogiri"
require "byebug"

def sign_in driver

    # Navigate to the login page
    driver.navigate.to("https://www.linkedin.com/login")

    # Find username and password fields and sign in with the given credentials
    username_field = driver.find_element(id: "username")
    password_field = driver.find_element(id: "password")
    submit_button = driver.find_element(class: "btn__primary--large")

    username_field.send_keys("ardaibis@gmail.com")
    password_field.send_keys("aRDAbORA2001!")
    submit_button.click()
end

def scrape driver

    # Navigate to specific company page after login
    company_url = "https://www.linkedin.com/company/matic-insurance/"
    driver.navigate.to(company_url)

    # Navigate to employees page
    parsed_company_page = Nokogiri::HTML(driver.page_source)
    employees_url = "https://www.linkedin.com/" + 
        parsed_company_page.css("a.ember-view.link-without-visited-state.inline-block")[0]
        .attributes["href"].value
    
    driver.navigate.to(employees_url)


end

# Configure driver and navigate to LinkedIn
caps = Selenium::WebDriver::Remote::Capabilities.chrome("goog:chromeOptions" => {detach: true})
driver = Selenium::WebDriver.for :chrome, desired_capabilities: caps

sign_in(driver)
scrape(driver)

driver.manage.timeouts.implicit_wait = 100

driver.quit
