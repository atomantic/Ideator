import Foundation

struct CorePackData {
    static let manifest = """
    {
      "id": "core",
      "name": "Core Pack",
      "version": "1.0.0",
      "description": "Essential prompt categories for daily ideation including wellness and personal growth",
      "author": "Idea Loom Team",
      "categories": [
        {
          "id": "personalDevelopment",
          "name": "Personal Development",
          "file": "personalDevelopment.tsv",
          "icon": "person.crop.circle.badge.checkmark",
          "color": "blue"
        },
        {
          "id": "professional",
          "name": "Professional",
          "file": "professional.tsv",
          "icon": "briefcase.fill",
          "color": "purple"
        },
        {
          "id": "creative",
          "name": "Creative",
          "file": "creative.tsv",
          "icon": "paintbrush.fill",
          "color": "orange"
        },
        {
          "id": "lifestyle",
          "name": "Lifestyle",
          "file": "lifestyle.tsv",
          "icon": "heart.fill",
          "color": "pink"
        },
        {
          "id": "relationships",
          "name": "Relationships",
          "file": "relationships.tsv",
          "icon": "person.2.fill",
          "color": "red"
        },
        {
          "id": "entertainment",
          "name": "Entertainment",
          "file": "entertainment.tsv",
          "icon": "tv.fill",
          "color": "yellow"
        },
        {
          "id": "travel",
          "name": "Travel & Adventure",
          "file": "travel.tsv",
          "icon": "airplane",
          "color": "green"
        },
        {
          "id": "learning",
          "name": "Learning & Skills",
          "file": "learning.tsv",
          "icon": "book.fill",
          "color": "indigo"
        },
        {
          "id": "financial",
          "name": "Financial",
          "file": "financial.tsv",
          "icon": "dollarsign.circle.fill",
          "color": "mint"
        },
        {
          "id": "socialImpact",
          "name": "Social Impact",
          "file": "socialImpact.tsv",
          "icon": "globe.americas.fill",
          "color": "teal"
        },
        {
          "id": "health",
          "name": "Health & Fitness",
          "file": "health.tsv",
          "icon": "heart.circle.fill",
          "color": "red"
        },
        {
          "id": "mindfulness",
          "name": "Mindfulness",
          "file": "mindfulness.tsv",
          "icon": "leaf.fill",
          "color": "green"
        },
        {
          "id": "selfcare",
          "name": "Self Care",
          "file": "selfcare.tsv",
          "icon": "sparkles",
          "color": "purple"
        },
        {
          "id": "gratitude",
          "name": "Gratitude",
          "file": "gratitude.tsv",
          "icon": "hands.sparkles",
          "color": "orange"
        }
      ]
    }
    """
    
    static func getTSVContent(for fileName: String) -> String? {
        switch fileName {
        case "personalDevelopment.tsv":
            return personalDevelopmentTSV
        case "professional.tsv":
            return professionalTSV
        case "creative.tsv":
            return creativeTSV
        case "lifestyle.tsv":
            return lifestyleTSV
        case "relationships.tsv":
            return relationshipsTSV
        case "entertainment.tsv":
            return entertainmentTSV
        case "travel.tsv":
            return travelTSV
        case "learning.tsv":
            return learningTSV
        case "financial.tsv":
            return financialTSV
        case "socialImpact.tsv":
            return socialImpactTSV
        case "health.tsv":
            return healthTSV
        case "mindfulness.tsv":
            return mindfulnessTSV
        case "selfcare.tsv":
            return selfcareTSV
        case "gratitude.tsv":
            return gratitudeTSV
        default:
            return nil
        }
    }
    
    private static let personalDevelopmentTSV = """
    text\ttags
    things to accomplish in the next decade\tgoals|milestones|personal
    habits to develop this year\thabits|self-improvement|daily
    fears to overcome\tcourage|growth|challenges
    skills I'd like to master\tlearning|abilities|expertise
    ways to improve my morning routine\troutine|productivity|morning
    things I'm grateful for today\tgratitude|mindfulness|appreciation
    things I would do if I knew I could not fail\tcourage|dreams|unlimited
    """
    
    private static let professionalTSV = """
    text\ttags
    business ideas to explore\tentrepreneurship|innovation|startup
    ways to improve my workspace\tproductivity|office|environment
    networking opportunities to pursue\tconnections|career|networking
    career goals for the next 5 years\tcareer|planning|future
    ways to add value to my team\tteamwork|contribution|leadership
    side projects to start this month\tprojects|initiative|creativity
    """
    
    private static let creativeTSV = """
    text\ttags
    short story concepts\twriting|fiction|storytelling
    inventions that would make life easier\tinnovation|problem-solving|invention
    art projects to try\tart|creativity|expression
    podcast episode ideas\tcontent|podcast|media
    app ideas that solve real problems\ttechnology|apps|solutions
    YouTube video concepts\tvideo|content|youtube
    """
    
    private static let lifestyleTSV = """
    text\ttags
    bucket list adventures\tadventure|experiences|bucket-list
    recipes to try this month\tcooking|food|culinary
    ways to simplify my life\tminimalism|simplicity|organization
    healthy habits to adopt\thealth|wellness|fitness
    ways to reduce stress\tstress-relief|relaxation|mental-health
    home improvement projects\thome|DIY|improvement
    """
    
    private static let relationshipsTSV = """
    text\ttags
    ways to show appreciation to loved ones\tlove|appreciation|gestures
    conversation starters for meaningful discussions\tcommunication|deep-talk|connection
    qualities I value in friendships\tfriendship|values|connections
    ways to strengthen my relationships\tbonding|improvement|connection
    people I should reconnect with\treconnection|friendship|nostalgia
    """
    
    private static let entertainmentTSV = """
    text\ttags
    movie night themes\tmovies|themes|entertainment
    book genres to explore\treading|genres|exploration
    games to play with friends\tgames|fun|social
    types of live events to experience\tevents|experiences|entertainment
    hobbies to explore\thobbies|interests|activities
    """
    
    private static let travelTSV = """
    text\ttags
    types of local adventures to try\tlocal|exploration|discovery
    dream vacation themes\tvacation|dreams|travel
    road trip themes or activities\troad-trip|themes|adventure
    unique travel experiences I'd enjoy\texperiences|adventure|unique
    weekend getaway themes\tweekend|themes|relaxation
    """
    
    private static let learningTSV = """
    text\ttags
    subjects I want to learn more about\teducation|topics|curiosity
    languages I'd like to learn\tlanguages|communication|culture
    documentary topics that interest me\tdocumentaries|topics|interest
    skills that would advance my career\tprofessional|skills|development
    topics I'm curious about\tcuriosity|knowledge|interest
    """
    
    private static let financialTSV = """
    text\ttags
    ways to save money\tsavings|budgeting|money
    investment opportunities to explore\tinvesting|wealth|future
    financial goals for this year\tgoals|planning|money
    ways to increase my income\tincome|earning|money
    """
    
    private static let socialImpactTSV = """
    text\ttags
    causes to support\tcharity|causes|giving
    ways to help my community\tcommunity|service|local
    environmental changes to make\tenvironment|sustainability|green
    volunteer opportunities to pursue\tvolunteering|service|helping
    random acts of kindness to perform\tkindness|giving|compassion
    """
    
    private static let healthTSV = """
    text\ttags
    healthy snacks to prepare\tnutrition|snacks|health
    movement activities that sound fun\texercise|movement|fun
    sleep hygiene improvements to make\tsleep|rest|health
    ways to stay hydrated\thydration|water|health
    stretches to do during work breaks\tstretching|breaks|wellness
    outdoor activities to try\toutdoor|nature|activity
    healthy meal prep ideas\tmeals|nutrition|planning
    ways to reduce screen time\tdigital|detox|health
    morning routines for energy\tmorning|routine|energy
    stress-relief activities\tstress|relief|relaxation
    """
    
    private static let mindfulnessTSV = """
    text\ttags
    moments today when I felt present\tmindfulness|presence|awareness
    thoughts I can let go of\trelease|thoughts|mindfulness
    sensations I'm noticing right now\tawareness|senses|present
    breathing exercises to try\tbreathing|meditation|calm
    meditation techniques to explore\tmeditation|practice|mindfulness
    ways to ground myself when anxious\tgrounding|anxiety|calm
    mindful activities for this week\tactivities|mindfulness|practice
    triggers I want to be aware of\ttriggers|awareness|growth
    intentions for tomorrow\tintentions|planning|mindfulness
    types of peaceful environments I enjoy\tpeace|environment|calm
    """
    
    private static let selfcareTSV = """
    text\ttags
    ways to pamper myself this weekend\tselfcare|relaxation|treat
    boundaries I need to set\tboundaries|protection|selfcare
    self-care rituals to establish\trituals|routine|care
    activities that recharge my energy\tenergy|recharge|rest
    ways to say no without guilt\tboundaries|guilt|assertiveness
    comfort activities for bad days\tcomfort|support|selfcare
    positive affirmations I need to hear\taffirmations|positive|self-love
    ways to celebrate small wins\tcelebration|achievement|recognition
    self-compassion practices to try\tcompassion|kindness|self
    rest activities that aren't sleep\trest|relaxation|recovery
    """
    
    private static let gratitudeTSV = """
    text\ttags
    small joys I experienced today\tgratitude|joy|appreciation
    people who made my life better\tpeople|gratitude|relationships
    abilities I'm grateful for\tabilities|gratitude|self
    challenges that helped me grow\tgrowth|challenges|gratitude
    simple pleasures I often overlook\tsimple|pleasure|mindfulness
    things about my body I appreciate\tbody|appreciation|gratitude
    opportunities I'm thankful for\topportunities|thankful|gratitude
    memories that make me smile\tmemories|happiness|past
    aspects of my home I love\thome|comfort|gratitude
    lessons I'm grateful to have learned\tlessons|learning|wisdom
    """
}