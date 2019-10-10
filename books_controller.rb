class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy]
  

  # GET /books
  # GET /books.json
  def index
    @books = Book.all
  end

  # GET /books/1
  # GET /books/1.json
  def show
  end

  # GET /books/new
  def new
    @book = Book.new
  end

  # GET /books/1/edit
  def edit
  end

  # POST /books
  # POST /books.json
  def create
    @book = Book.new(book_params)

    respond_to do |format|
      if @book.save
        format.html { redirect_to @book, notice: 'Book was successfully created.' }
        format.json { render :show, status: :created, location: @book }
      else
        format.html { render :new }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /books/1
  # PATCH/PUT /books/1.json
  def update
    respond_to do |format|
      if @book.update(book_params)
        format.html { redirect_to @book, notice: 'Book was successfully updated.' }
        format.json { render :show, status: :ok, location: @book }
      else
        format.html { render :edit }
        format.json { render json: @book.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /books/1
  # DELETE /books/1.json
  def destroy
    @book.destroy
    respond_to do |format|
      format.html { redirect_to books_url, notice: 'Book was successfully destroyed.' }
      format.json { head :no_content }
    end
  end
  
  def search
	  if params[:search].blank?  
		redirect_to('index', alert: "Empty field!") and return  
	  elsif params[:search_by]=='title' 
			@book = params[:search].downcase  
			@results = Book.all.where("lower(title) LIKE :search", search: @book)
	  elsif params[:search_by]=='authors'
			@book = params[:search].downcase  
			@results = Book.all.where("lower(authors) LIKE :search", search: @book)
	  elsif params[:search_by]=='published'
			@book = params[:search].downcase  
			@results = Book.all.where("lower(published) LIKE :search", search: @book)
	  elsif params[:search_by]=='category'
			@book = params[:search].downcase  
			@results = Book.all.where("lower(category) LIKE :search", search: @book)
	  else
			redirect_to('index', alert: "Empty field!")
	  end  
  end
  
  def checkout # check if the given book is a special book or not
    @book = Book.find(params[:id])
    if(@book.count>0)
      if Checkout.where(:student_id => current_student.id , :book_id => @book.id).nil?
        @checkout = Checkout.new(:student_id => current_student.id , :book_id => @book.id , :isssue_date => Date.today , :return_date =>nil , :validity => Library.find(@book.library_id).borrow_limit)
        flash[:notice] = "Book Successfully Checked Out"
        @book.decrement(:count)
        @checkout.save!
        @book.save!
      else 
        flash[:notice] = "Book Already Checked Out"
      end  
    else
      # put the book into reservetion list and pop out the message saying reservation is made
    end
	  redirect_to action: "index"
  end

  def returnBook
    if(@book.count>0) 
      if Checkout.where(:student_id => current_student.id , :book_id => @book.id).nil?
        @checkout = Checkout.where(:student_id => current_student.id , :book_id => @book.id , :isssue_date => Date.today , :return_date =>nil , :validity => Library.find(@book.library_id).borrow_limit)
        @checkout.destroy
        flash[:notice] = "Book Successfully returned"
        @book.increment(:count)
        @book.save!
      else 
        flash[:notice] = "Book is not checked out"
      end  
    else
      # book has a request assign book to new user with new dates and keep the count same
    end
	  redirect_to action: "index"
  end

  def bookmark
    @book = Book.find(params[:id])
    @transaction = Transaction.where(:isbn => @book.isbn , :email => current_student.email, :bookmarks => true).first
    if !@transaction.nil?
      flash[:notice] = "Book is already bookmarked!!"
    else
      flash[:notice] = "Book Added to your bookmarks"
    end
    Transaction.
        find_or_initialize_by(:isbn => @book.isbn , :email => current_student.email).
        update_attributes!(:email => current_student.email,:bookmarks => true)
    redirect_to action: "index"
  end

  def unbookmark
    @book = Book.find(params[:id])
    Transaction.
        find_or_initialize_by(:isbn => @book.isbn , :email => current_student.email).
        update_attributes!(:email => current_student.email,:bookmarks => false)
    flash[:notice] = "Book Removed from your bookmarks"
    redirect_to action: "getBookmarkBooks"
  end


  def requestBook
    @book = Book.find(params[:id])
    @transaction = Transaction.where(:isbn => @book.isbn , :email => current_student.email, :request => true).first
    if !@transaction.nil?
      flash[:notice] = "Book is already Requested!!"
    else
      flash[:notice] = "Book Added to your Requested Lists"
    end
    Transaction.
        find_or_initialize_by(:isbn => @book.isbn , :email => current_student.email).
        update_attributes!(:email => current_student.email,:request => true)
    redirect_to action: "index"
  end

  def repealRequest
    @book = Book.find(params[:id])
    Transaction.
        find_or_initialize_by(:isbn => @book.isbn , :email => current_student.email).
        update_attributes!(:email => current_student.email,:request => false)
    @book.save!

    redirect_to action: "getBookmarkBooks"
  end
  
  def librarian_book_view
    @books = Book.all
  end

  def getBookmarkBooks
    # @book = Book.find(params[:id])
    @bookmark = Book.where(isbn: Transaction.select('isbn').where(email: current_student.email,bookmarks: true))
    @checkout = Book.where(isbn: Transaction.select('isbn').where(email: current_student.email, checkout: true))
    @request = Book.where(isbn: Transaction.select('isbn').where(email: current_student.email, request: true))
    #redirect_to action: "index"
  end

  def list_checkedoutBooks
    #ook.where(isbn: Transaction.select('isbn').where(email: current_student.email,bookmarks: true))
    @books = Book.where(isbn: Transaction.select('isbn').where(checkout: true))
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_book
      @book = Book.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def book_params
      params.require(:book).permit(:isbn, :title, :authors, :language, :published, :edition, :cover, :subject, :summary, :category, :special_collection, :library_id, :count)
    end

end
