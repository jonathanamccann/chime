require_relative "./chime/version"
require_relative './chime/emotions/emotion_bank.rb'
require_relative './chime/emotions/term_polarities.rb'
require_relative './chime/emotions/stopwords.rb'
require_relative './chime/emotions/term_categories.rb'
require_relative './chime/emotions/emotion_bank_phrases.rb'

require 'lingua/stemmer'

module Chime

  # this method returns the best-fit emotion for the status message
  def self.emotion(message)
    # get the emotion for which the emotion score value is highest
    Chime.get_emotion_score(message, EmotionBank.get_term_emotions, build_term_frequencies(message))
  end

    # this method returns the best-fit emotion for the status message
  def self.category(message)
    # get the emotion for which the emotion score value is highest
    Chime.get_category_score(message, TermCategories.get_term_categories, build_term_frequencies(message))
  end

  # this method returns the polarity value for the status message
  # (normalized by the number of 'polar' words that the status
  # message contains)
  def self.polarity(message)
    # get the polarity for which the polarity score value is highest
    Chime.get_polarity_score(message, TermPolarities.get_term_polarities, Chime.build_term_frequencies(message))
  end

#TODO: Utilize stems and stop words within the next two methods.

#This method works off of phrases instead of just words
  def self.category_phrases(array)
    array.map{|e| TermCategories.get_term_categories.find(proc{[nil,"Undefined"]}){|k,v| e.downcase.include? k.downcase}.last}
  end


#This method works off of phrases instead of just words  
  def self.emotion_phrases(array)
    array.map{|e| EmotionBankPhrases.get_term_emotion_phrases.find(proc{[nil,"Ambiguous"]}){|k,v| e.downcase.include? k}.last}
  end

#Pull EmotionBankPhrases into strictly positive hash
  def self.emotion_phrases_positive_array
    EmotionBankPhrases.get_term_emotion_phrases.select { |key, value| value.to_s.match("Positive") }
  end

#Pull EmotionBankPhrases into strictly negative hash
   def self.emotion_phrases_negative_array
    EmotionBankPhrases.get_term_emotion_phrases.select { |key, value| value.to_s.match("Negative") }
  end

            

  private

  	# this method reads the text of the status message
  	# inputed by the user, removes common english words,
  	# strips punctuation and capitalized letters, isolates
  	# the stem of the word, and ultimately produces a hash
  	# where the keys are the stems of the remaining words,
  	# and the values are their respective frequencies within
  	# the status message
  	def self.build_term_frequencies(message, term_frequencies = {})
  		# clean the text of the status message
      happy_emoticon = happy_emoticon(message)
      sad_emoticon = sad_emoticon(message)
  		words = words_from_message_text(message)
  		#filter for english stopwords
  		stopwords = Stopwords.stopwords
  		words = words - stopwords
  		#get word stems
  		word_stems = Chime.get_word_stems words
  		#create term_frequencies
  		#return term frequency hash
    	create_term_frequencies(word_stems, term_frequencies)
    end

  	# this method takes an array of words an returns an array of word stems
  	def self.get_word_stems(words, output=[])
  		stemmer = Lingua::Stemmer.new(:language => "en")
  		words.each do |word|
  			output << stemmer.stem(word)
  		end
  		output
  	end

  	# this method takes an emotion-words hash and a hash containing word
  	# frequencies for the status message, calculates a numerical score
  	# for each possble emotion, and returns the emotion with the highest
  	# "score"
  	def self.get_emotion_score(message, emotions, term_frequencies, emotion_score = {})
  		term_frequencies.each do |key,value|
  			set_emotions(emotions, emotion_score, key, value)
  		end
  		# return an emotion_score_hash to be processed by emotion
      # get clue from any emoticons present
      check_emoticon_for_emotion(emotion_score, message)
  	end

        # this method takes an emotion-words hash and a hash containing word
    # frequencies for the status message, calculates a numerical score
    # for each possble emotion, and returns the emotion with the highest
    # "score"
    def self.get_category_score(message, categories, term_frequencies, category_score = {})
      term_frequencies.each do |key,value|
        set_categories(categories, category_score, key, value)
      end
      # return an emotion_score_hash to be processed by emotion
      # get clue from any emoticons present
      check_emoticon_for_category(category_score, message)
    end

  	# this method gives the status method a normalized polarity
  	# value based on the words it contains
  	def self.get_polarity_score (message, polarity_hash, term_frequencies, polarity_scores = [])
  		term_frequencies.each do |key, value|
              set_polarities(key, value, polarity_hash, polarity_scores)
  		end

  		# return an polarity_score_hash to be processed by polarity method
  		# return an emotion_score_hash to be processed by emotion
      # get clue from any emoticons present
      check_emoticon_for_polarity(polarity_scores, message)
  	end

    def self.happy_emoticon(message)
      (message.include?(":)") || message.include?(":-)") || message.include?(":]") || message.include?(":-]"))
    end

    def self.sad_emoticon(message)
      (message.include?(":(") || message.include?(":-(") || message.include?(":[") || message.include?(":-["))
    end

    def self.words_from_message_text(message)
      message.gsub!(/[^a-z ]/i, '')
      message.downcase!
      message.gsub!(/((([A-Za-z]{3,9}:(?:\/\/)?)(?:[-;:&=\+\$,\w]+@)?[A-Za-z0-9.-]+|(?:www.|[-;:&=\+\$,\w]+@)[A-Za-z0-9.-]+)((?:\/[\+~%\/.\w-_]*)?\??(?:[-\+=&;%@.\w_]*)#?(?:[\w]*))?)/, '')
      message.gsub!(/(?=\w*h)(?=\w*t)(?=\w*t)(?=\w*p)\w*/, '')
      message.gsub!(/\s\s+/,' ')
      message.split(" ")
    end

    def self.set_emotions(emotions, emotion_score, term, frequency)
      emotions.keys.each do |k|
        store_emotions(emotions, emotion_score, k, term, frequency)
      end
    end

    def self.set_categories(categories, category_score, term, frequency)
      categories.keys.each do |k|
        store_categories(categories, category_score, k, term, frequency)
      end
    end

    def self.set_polarities(term, frequency, polarity_hash, polarity_scores)
      polarity_hash.keys.each do |k|
        store_polarities(term, k, polarity_hash, polarity_scores)
      end
    end

    def self.store_emotions(emotions, emotion_score, emotion, term, frequency)
      if emotions[emotion].include?(term)
        emotion_score[emotion] ||= 0
        emotion_score[emotion] += frequency
      end
    end

    def self.store_categories(categories, category_score, category, term, frequency)
      if categories[category].include?(term)
        category_score[category] ||= 0
        category_score[category] += frequency
      end
    end

    def self.store_polarities(term, word, polarity_hash, polarity_scores)
      if term == word
        polarity_scores << (polarity_hash[word].to_f)
      end
    end

    def self.check_emoticon_for_emotion(emotion_score, message)
      if (happy_emoticon(message) && sad_emoticon(message))
         "ambiguous"
      elsif happy_emoticon(message)
         "joy"
      elsif sad_emoticon(message)
         "sadness"
      else
        return_emotion_score(emotion_score)
      end
    end

    def self.check_emoticon_for_category(category_score, message)
      if (happy_emoticon(message) && sad_emoticon(message))
         "ambiguous-cat"
      elsif happy_emoticon(message)
         "joy-cat"
      elsif sad_emoticon(message)
         "sadness-cat"
      else
        return_category_score(category_score)
      end
    end

    def self.return_emotion_score(emotion_score)
      ## 0 if unable to detect emotion
      if emotion_score == {}
        "ambiguous"
      else
        emotion_score.max_by{|k, v| v}[0]
      end
    end

    def self.return_category_score(category_score)
      ## 0 if unable to detect emotion
      if category_score == {}
        "ambiguous-cat"
      else
        category_score.max_by{|k, v| v}[0]
      end
    end

    def self.check_emoticon_for_polarity(polarity_scores, message)
      if (happy_emoticon(message) && sad_emoticon(message))
        score = 5
      elsif happy_emoticon(message)
        score = 8
      elsif sad_emoticon(message)
        score = 2
      else
        return_polarity_scores(polarity_scores)
      end
    end

    def self.return_polarity_scores(polarity_scores)
      if polarity_scores == []
        # polarity unreadable; return a neutral score of 5
        5
      else
        polarity_scores.inject(0.0){ |sum, el| sum + el}/polarity_scores.length
      end
    end

    def self.create_term_frequencies(word_stems, term_frequencies)
      word_stems.each do |stem|
        term_frequencies[stem] = word_stems.count(stem)
      end
      term_frequencies
    end


end
