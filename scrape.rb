require "selenium-webdriver"
require "Nokogiri"
require "byebug"
require 'io/console'

def login driver, username, password

    # Find username and password fields and login with the given credentials
    username_field = driver.find_element(id: "username")
    password_field = driver.find_element(id: "password")
    submit_button = driver.find_element(class: "btn__primary--large")

    username_field.clear
    password_field.clear

    username_field.send_keys(username)
    password_field.send_keys(password)

    submit_button.click()
end

def scrape driver

    # Navigate to specific company page after login
    company_url = "https://www.linkedin.com/company/somera/"
    driver.navigate.to(company_url)

    # Navigate to employees page
    parsed_company_page = Nokogiri::HTML(driver.page_source)
    employees_url = "https://www.linkedin.com/" + 
        parsed_company_page.css("a.ember-view.link-without-visited-state.inline-block")[0]
        .attributes["href"].value
    
    driver.navigate.to(employees_url)

    # Parse the first employee page
    parsed_employee_page = Nokogiri::HTML(driver.page_source)
    
    # Calculate the number of pages for the pagination
    employee_listings = parsed_employee_page.css(".entity-result")
    employee_per_page = employee_listings.size
    total_employee_count = parsed_employee_page.css(".pb2.t-black--light.t-14")
        .text.split(" ")[0].to_i

    last_page = (total_employee_count.to_f / employee_per_page.to_f).ceil

    current_page = 1

    # Initialize empty array for the employees
    employees = Array.new

    # Iterate over every employee page
    while current_page <= last_page
        
        if current_page != 1
            driver.navigate.to(employees_url + "&page=#{current_page}")
            parsed_employee_page = Nokogiri::HTML(driver.page_source)
            employee_listings = parsed_employee_page.css(".entity-result")
        end

        # For each employee listing extract the relevant information and append it to employees
        employee_listings.each do |employee_listing|
            employee = {
                person: employee_listing.css("a").text.strip.split(/View|&|\+/).first,
                company: parsed_company_page.css(".org-top-card-summary__title").text.strip,
                title: employee_listing.css(".entity-result__primary-subtitle").text.strip,
                location: employee_listing.css(".entity-result__secondary-subtitle").text.strip,
                url: employee_listing.css(".app-aware-link")[0].attributes["href"].value,
            }

            employees << employee
        end

        current_page += 1
    end

    return employees
end

def main

    # Configure driver
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    driver = Selenium::WebDriver.for :chrome, options: options

    # Navigate to the login page
    driver.navigate.to("https://www.linkedin.com/login")

    loop do

        # Try to login to LinkedIn
        print "Enter LinkedIn mail: "
        username = gets.chomp

        print "Enter LinkedIn password: "
        password = STDIN.noecho(&:gets).chomp

        login(driver, username, password)

        puts

        # If successful break else try again
        if driver.current_url == "https://www.linkedin.com/feed/"
            puts "Login successful"
            break
        end

        puts "Login failed"
    end

    # Get the employees of the given company
    employees = scrape(driver)

    byebug

    driver.quit
end

main
