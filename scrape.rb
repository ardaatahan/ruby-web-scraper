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

    # Parse the first employee page
    parsed_employee_page = Nokogiri::HTML(driver.page_source)
    
    # 
    employee_listings = parsed_employee_page.css(".entity-result")
    employee_per_page = employee_listings.size
    total_employee_count = parsed_employee_page.css(".pb2.t-black--light.t-14")
        .text.split(" ")[0].to_i

    last_page = (total_employee_count.to_f / employee_per_page.to_f).ceil

    current_page = 1
    employees = Array.new

    while current_page <= last_page
        
        if current_page != 1
            driver.navigate.to(employees_url + "&page=#{current_page}")
            parsed_employee_page = Nokogiri::HTML(driver.page_source)
            employee_listings = parsed_employee_page.css(".entity-result")
        end

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

# Configure driver and navigate to LinkedIn
driver = Selenium::WebDriver.for(:chrome)

sign_in(driver)

employees = scrape(driver)

driver.quit
